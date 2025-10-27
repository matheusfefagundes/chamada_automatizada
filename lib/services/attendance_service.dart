import 'dart:async';
import 'dart:convert'; // Importar dart:convert
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importar shared_preferences
import '../models/attendance_record.dart';
import 'settings_service.dart';

class AttendanceService with ChangeNotifier {
  final SettingsService _settingsService;
  final SharedPreferences _prefs; // Adicionar SharedPreferences
  Timer? _timer;

  final ValueNotifier<bool> isChallengeActive = ValueNotifier(false);
  final ValueNotifier<double?> currentDistance = ValueNotifier(null);
  Completer<bool>? _challengeCompleter;

  List<AttendanceRecord> _history = [];
  bool _isSchedulerRunning = false;
  bool _isProcessing = false;
  DateTime? _nextRoundTime;
  int _currentRound = 0; // Mantém a contagem da rodada atual

  // Chave para salvar o histórico
  static const _historyKey = 'attendance_history';

  // Coordenadas e distância
  final double _targetLatitude = -26.304309480393407;
  final double _targetLongitude = -48.85103922453631;
  final double _maxDistanceInMeters = 1000;

  List<AttendanceRecord> get history => _history;
  bool get isSchedulerRunning => _isSchedulerRunning;
  bool get isProcessing => _isProcessing;
  DateTime? get nextRoundTime => _nextRoundTime;
  AttendanceRecord? get lastRecord {
    // Ordena por rodada descendente para pegar o último
    final sortedHistory = List<AttendanceRecord>.from(_history)
      ..sort((a, b) => b.round.compareTo(a.round));
    return sortedHistory.isEmpty ? null : sortedHistory.first;
  }

  // Getter para a rodada atual
  int get currentRound => _currentRound;
  double get maxDistanceInMeters => _maxDistanceInMeters;

  AttendanceService(this._settingsService, this._prefs) {
    // Modificar construtor
    _loadHistory(); // Carregar histórico ao iniciar
    // Opcional: Iniciar o scheduler se estava ativo na última vez
    // _isSchedulerRunning = _prefs.getBool('scheduler_running_state') ?? false;
    // if (_isSchedulerRunning) {
    //   startScheduler(resume: true); // Precisaria de lógica para resumir
    // }
  }

  // --- Funções de Persistência do Histórico ---
  Future<void> _saveHistory() async {
    // Salva apenas o histórico do dia atual
    final todayHistory = _getTodayHistory();
    List<String> historyJsonList =
        todayHistory.map((record) => json.encode(record.toJson())).toList();
    await _prefs.setStringList(_historyKey, historyJsonList);
  }

  void _loadHistory() {
    final List<String>? historyJsonList = _prefs.getStringList(_historyKey);
    if (historyJsonList != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _history = historyJsonList
          .map((jsonString) {
            try {
              return AttendanceRecord.fromJson(json.decode(jsonString));
            } catch (e) {
              debugPrint("Erro ao decodificar registro do histórico: $e");
              return null; // Retorna null para registros inválidos
            }
          })
          .where((record) {
            // Filtra para manter apenas registros de hoje e válidos
            if (record == null) return false;
            final recordDate =
                DateTime(record.date.year, record.date.month, record.date.day);
            return recordDate.isAtSameMomentAs(today);
          })
          .toList()
          .cast<AttendanceRecord>(); // Converte para o tipo correto

      // Atualiza a rodada atual com base no histórico carregado
      _currentRound =
          _history.map((r) => r.round).fold(0, (max, r) => r > max ? r : max);
    } else {
      _history = [];
      _currentRound = 0;
    }
    notifyListeners();
  }

  // Helper para pegar o histórico apenas do dia atual
  List<AttendanceRecord> _getTodayHistory() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _history.where((record) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      return recordDate.isAtSameMomentAs(today);
    }).toList();
  }
  // --- Fim Funções de Persistência ---

  Future<Position> _determinePosition() async {
    // ... (código existente sem alterações)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> runAttendanceRound({bool manual = false}) async {
    final student = _settingsService.getStudent();
    if (student == null) return;

    // Verifica se o dia mudou desde o último registro, se sim, reseta o histórico e a rodada
    _resetIfNewDay();

    if (!manual && _isSchedulerRunning) {
      // Incrementa apenas se for uma rodada automática e o scheduler estiver ativo
      _currentRound++;
    } else if (manual) {
      // Para rodada manual, define a rodada como a próxima disponível no dia
      _currentRound = _getTodayHistory().length + 1;
    }

    // Limita ao número máximo de rodadas configurado se for automático
    final maxRounds = _settingsService.getSettings().numberOfRounds;
    if (!manual && _currentRound > maxRounds) {
      _currentRound = maxRounds; // Trava na última rodada
      stopScheduler(); // Para o agendador se excedeu
      return; // Não executa a rodada extra
    }

    bool challengePassed = false;
    String result = 'Ausente';
    try {
      Position position = await _determinePosition();
      double distanceInMeters = Geolocator.distanceBetween(
        _targetLatitude,
        _targetLongitude,
        position.latitude,
        position.longitude,
      );
      currentDistance.value = distanceInMeters;

      if (distanceInMeters <= _maxDistanceInMeters) {
        challengePassed = await _triggerLivenessChallenge();
        result = challengePassed ? 'Presente' : 'Ausente (Falha Desafio)';
      } else {
        result = 'Fora do Local';
      }
    } catch (e) {
      result = 'Erro ($e)'; // Melhorar mensagem de erro
      currentDistance.value = null;
      debugPrint("Erro ao obter localização: $e");
    }

    final record = AttendanceRecord(
      studentId: student.id,
      studentName: student.name,
      date: DateTime.now(),
      // Usa _currentRound que foi calculado acima
      round: _currentRound,
      timestamp: DateTime.now(),
      result: result,
      challengePassed: challengePassed,
    );

    // Remove registro anterior da mesma rodada (se houver, ex: forçou manual depois de automático)
    _history.removeWhere(
        (r) => r.round == record.round && _isSameDay(r.date, record.date));
    _history.add(record);
    await _saveHistory(); // Salva após adicionar

    // Agendar próxima rodada automática apenas se não for manual e ainda houver rodadas
    if (_isSchedulerRunning &&
        !manual &&
        _currentRound < _settingsService.getSettings().numberOfRounds) {
      final interval = _settingsService.getSettings().intervalInMinutes;
      _scheduleNextRound(Duration(minutes: interval));
    } else if (_isSchedulerRunning &&
        !manual &&
        _currentRound >= _settingsService.getSettings().numberOfRounds) {
      // Se era a última rodada automática
      _nextRoundTime = null; // Limpa a próxima rodada
      // Considerar parar o scheduler aqui ou deixar ele parar no próximo tick do timer
      // stopScheduler(); // O timer já vai parar no próximo tick
    }

    notifyListeners();
  }

  // Função helper para verificar se duas datas são no mesmo dia
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Função para resetar o histórico e a rodada se for um novo dia
  void _resetIfNewDay() {
    if (_history.isNotEmpty) {
      final lastRecordDate = _history.last.date;
      final now = DateTime.now();
      if (!_isSameDay(lastRecordDate, now)) {
        _history = []; // Limpa o histórico em memória
        _currentRound = 0; // Reseta a contagem da rodada
        _saveHistory(); // Salva o histórico vazio (limpa o do dia anterior)
        notifyListeners();
      }
    }
  }

  void startScheduler() {
    _resetIfNewDay(); // Garante que começa limpo se for um novo dia
    if (_isSchedulerRunning) return; // Não inicia se já estiver rodando

    _isSchedulerRunning = true;
    // Define a rodada atual baseada no histórico carregado do dia
    _currentRound = _getTodayHistory()
        .map((r) => r.round)
        .fold(0, (max, r) => r > max ? r : max);

    notifyListeners();
    _scheduleNextAutomaticRound(); // Chama a função que agenda ou executa
  }

  void _scheduleNextAutomaticRound() {
    if (!_isSchedulerRunning) return; // Só agenda se estiver ativo

    final settings = _settingsService.getSettings();
    final interval = Duration(minutes: settings.intervalInMinutes);

    // Se a rodada atual é 0 (início) ou já passou o intervalo desde a última rodada
    bool shouldRunNow = false;
    if (_currentRound == 0) {
      shouldRunNow =
          true; // Primeira rodada inicia "imediatamente" (após pequeno delay)
    } else if (_history.isNotEmpty) {
      final lastTime = lastRecord!.timestamp; // Usa o getter lastRecord
      if (DateTime.now().difference(lastTime) >= interval) {
        // Se já passou o tempo, deveria rodar agora, mas vamos agendar para evitar loops rápidos
        //shouldRunNow = true; // Comentei para evitar execuções muito rápidas em sequência
      }
    }

    // Cancela timer anterior para evitar múltiplos timers
    _timer?.cancel();

    if (_currentRound < settings.numberOfRounds) {
      Duration delay = shouldRunNow
          ? const Duration(seconds: 5)
          : interval; // Delay curto para primeira ou se já passou tempo

      // Se já passou o tempo da última + intervalo, agenda para daqui a alguns segundos
      if (!shouldRunNow && _history.isNotEmpty) {
        final nextScheduled = lastRecord!.timestamp.add(interval);
        if (DateTime.now().isAfter(nextScheduled)) {
          delay = const Duration(
              seconds: 10); // Agendar para daqui a 10s se o tempo já passou
        } else {
          // Calcula o tempo restante até a próxima execução agendada
          delay = nextScheduled.difference(DateTime.now());
        }
      }

      _nextRoundTime = DateTime.now().add(delay); // Atualiza próxima hora
      notifyListeners();

      _timer = Timer(delay, () {
        // Verifica de novo se ainda deve rodar (pode ter sido parado)
        if (_isSchedulerRunning && _currentRound < settings.numberOfRounds) {
          runAttendanceRound(); // Executa a rodada automática (incrementará _currentRound)
          // A própria runAttendanceRound vai re-agendar a próxima se necessário
        } else {
          stopScheduler(); // Para se não deve mais rodar
        }
      });
    } else {
      // Já completou todas as rodadas
      stopScheduler();
    }
  }

  void stopScheduler() {
    _timer?.cancel();
    _timer = null; // Limpa a referência do timer
    _isSchedulerRunning = false;
    _nextRoundTime = null;
    notifyListeners();
    // Opcional: Salvar o estado do scheduler
    // _prefs.setBool('scheduler_running_state', _isSchedulerRunning);
  }

  void _scheduleNextRound(Duration after) {
    if (!_isSchedulerRunning) return; // Não agenda se não estiver ativo

    _nextRoundTime = DateTime.now().add(after);
    notifyListeners();

    // O agendamento real acontece em _scheduleNextAutomaticRound
    // Apenas atualizamos a UI aqui. O timer será recriado lá.
    // Isso evita o problema de ter o _timer antigo ainda ativo
    // quando _scheduleNextRound é chamada dentro de runAttendanceRound.
    // Vamos chamar _scheduleNextAutomaticRound aqui de forma assíncrona
    // para garantir que o estado seja atualizado antes de reagendar.
    Future.microtask(() => _scheduleNextAutomaticRound());
  }

  Future<void> runSingleAttendanceRound() async {
    _isProcessing = true;
    notifyListeners();
    // Passa a rodada manualmente calculada
    await runAttendanceRound(manual: true);
    _isProcessing = false;
    notifyListeners();
  }

  Future<bool> _triggerLivenessChallenge() async {
    // ... (código existente sem alterações)
    _challengeCompleter = Completer<bool>();
    isChallengeActive.value = true;

    bool result = await _challengeCompleter!.future;

    isChallengeActive.value = false;
    return result;
  }

  void completeChallenge(bool success) {
    // ... (código existente sem alterações)
    if (_challengeCompleter != null && !_challengeCompleter!.isCompleted) {
      _challengeCompleter!.complete(success);
    }
  }

  Future<String?> exportToCsv() async {
    // Pega apenas o histórico de hoje para exportar
    final todayHistory = _getTodayHistory();
    if (todayHistory.isEmpty) return "Nenhum dado de hoje para exportar.";

    final header = [
      'student_id',
      'student_name',
      'date', // YYYY-MM-DD
      'round', // Número da rodada
      'status', // P/F/...
      'recorded_at', // ISO8601 Timestamp
      'notes',
      'validation_method'
    ];
    List<List<String>> rows = [
      header,
      ...todayHistory.map((r) => r.toCsvRow()) // Usa o método do modelo
    ];
    String csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    try {
      final directory = await getApplicationDocumentsDirectory();
      // Usar data no nome do ficheiro
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final path = "${directory.path}/chamada_$dateStr.csv";
      final file = File(path);
      await file.writeAsString(csv);
      return path;
    } catch (e) {
      debugPrint("Erro ao salvar arquivo CSV: $e");
      return "Erro ao salvar arquivo: $e";
    }
  }

  // --- Funções para o Dashboard (Nota 7) ---

  // Retorna o status de uma rodada específica do dia atual
  String getRoundStatus(int roundNumber) {
    _resetIfNewDay(); // Garante que estamos a olhar para o dia certo
    final todayHistory = _getTodayHistory();
    final record =
        todayHistory.where((r) => r.round == roundNumber).firstOrNull;

    if (record != null) {
      return record
          .result; // Retorna o resultado registrado (Presente, Ausente, Fora do Local, etc.)
    }

    // Se não há registro para a rodada
    final settings = _settingsService.getSettings();
    if (roundNumber > settings.numberOfRounds) {
      return "Inválida"; // Rodada além das configuradas
    }

    if (!_isSchedulerRunning && _currentRound < roundNumber) {
      return "Agendador Inativo";
    }

    if (_isSchedulerRunning && _currentRound >= roundNumber) {
      // Se o scheduler está rodando e já passamos desta rodada, mas não há registro, algo estranho aconteceu
      // Poderia ser um erro, mas vamos tratar como "Pendente" ou "Não executada"
      // No entanto, pela lógica atual, se passou a rodada, deveria ter um registro.
      // Se chegou aqui sem registro, pode ser que a rodada ainda não correu.
      // Vamos verificar se a próxima rodada é esta ou posterior.
      if (nextRoundTime != null && roundNumber > _currentRound) {
        return "A iniciar";
      } else {
        // Se já passou a hora e não tem registro (pode ter falhado ou sido pulada)
        return "Não registrada";
      }
    }

    if (_isSchedulerRunning &&
        roundNumber == _currentRound + 1 &&
        nextRoundTime != null) {
      return "A iniciar"; // É a próxima rodada agendada
    }

    if (_isSchedulerRunning && roundNumber > _currentRound + 1) {
      return "Agendada"; // Rodadas futuras
    }

    // Caso padrão ou se scheduler inativo e a rodada ainda não chegou
    return "Pendente";
  }

  // Retorna uma lista com os status de todas as rodadas configuradas
  List<Map<String, dynamic>> getAllRoundsStatus() {
    final settings = _settingsService.getSettings();
    final List<Map<String, dynamic>> roundsStatus = [];
    for (int i = 1; i <= settings.numberOfRounds; i++) {
      roundsStatus.add({
        'round': i,
        'status': getRoundStatus(i),
      });
    }
    return roundsStatus;
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Não se esqueça de remover listeners se adicionar algum
    super.dispose();
  }
}

// Adicionar esta linha no main.dart ANTES de runApp
// final prefs = await SharedPreferences.getInstance();
// E passar prefs para os providers:
// final settingsService = SettingsService(prefs);
// final attendanceService = AttendanceService(settingsService, prefs); // Modificado
//
// ChangeNotifierProvider.value(value: attendanceService), // Passar a instância criada
