import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_core/firebase_core.dart'; // <--- O CORRETOR DO ERRO
import '../models/attendance_record.dart';
import 'settings_service.dart';

class AttendanceService with ChangeNotifier {
  final SettingsService _settingsService;
  final SharedPreferences _prefs;
  Timer? _timer;

  final ValueNotifier<bool> isChallengeActive = ValueNotifier(false);
  final ValueNotifier<double?> currentDistance = ValueNotifier(null);
  Completer<bool>? _challengeCompleter;

  List<AttendanceRecord> _history = [];
  bool _isSchedulerRunning = false;
  bool _isProcessing = false;
  DateTime? _nextRoundTime;
  int _currentRound = 0;

  static const _historyKey = 'attendance_history';
  // Coordenadas alvo e raio
  final double _targetLatitude = -26.304309480393407; 
  final double _targetLongitude = -48.851039224536311;
  final double _maxDistanceInMeters = 1000;//Em metros

  List<AttendanceRecord> get history => _history;
  bool get isSchedulerRunning => _isSchedulerRunning;
  bool get isProcessing => _isProcessing;
  DateTime? get nextRoundTime => _nextRoundTime;
  AttendanceRecord? get lastRecord {
    final sortedHistory = List<AttendanceRecord>.from(_history)
      ..sort((a, b) => b.round.compareTo(a.round));
    return sortedHistory.isEmpty ? null : sortedHistory.first;
  }
  int get currentRound => _currentRound;
  double get maxDistanceInMeters => _maxDistanceInMeters;

  AttendanceService(this._settingsService, this._prefs) {
    _loadHistory();
  }

  Future<void> _saveHistory() async {
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
              debugPrint("Erro ao decodificar registro: $e");
              return null;
            }
          })
          .where((record) {
            if (record == null) return false;
            final recordDate = DateTime(record.date.year, record.date.month, record.date.day);
            return recordDate.isAtSameMomentAs(today);
          })
          .toList()
          .cast<AttendanceRecord>();

      _currentRound = _history.map((r) => r.round).fold(0, (max, r) => r > max ? r : max);
    } else {
      _history = [];
      _currentRound = 0;
    }
    notifyListeners();
  }

  List<AttendanceRecord> _getTodayHistory() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _history.where((record) {
      final recordDate = DateTime(record.date.year, record.date.month, record.date.day);
      return recordDate.isAtSameMomentAs(today);
    }).toList();
  }

  Future<Position> _determinePosition() async {
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

  //Salvar no Firebase
  Future<void> _syncToExternalDatabase(AttendanceRecord record) async {
    try {
      // Verifica se o Firebase foi inicializado antes de tentar usar
      if (Firebase.apps.isEmpty) return;

      await FirebaseFirestore.instance.collection('presencas').add({
        ...record.toJson(),
        'synced_at': FieldValue.serverTimestamp(),
      });
      debugPrint("Registro sincronizado com Firebase.");
    } catch (e) {
      debugPrint("Erro ao salvar no banco externo: $e");
    }
  }

  Future<void> runAttendanceRound({bool manual = false}) async {
    final student = _settingsService.getStudent();
    if (student == null) return;

    _resetIfNewDay();

    if (!manual && _isSchedulerRunning) {
      _currentRound++;
    } else if (manual) {
      _currentRound = _getTodayHistory().length + 1;
    }

    final maxRounds = _settingsService.getSettings().numberOfRounds;
    if (!manual && _currentRound > maxRounds) {
      _currentRound = maxRounds;
      stopScheduler();
      return;
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
        result = challengePassed ? 'Presente' : 'Ausente';
      } else {
        result = 'Fora do Local';
      }
    } catch (e) {
      result = 'Erro ($e)';
      currentDistance.value = null;
      debugPrint("Erro ao obter localização: $e");
    }

    final record = AttendanceRecord(
      studentId: student.id,
      studentName: student.name,
      date: DateTime.now(),
      round: _currentRound,
      timestamp: DateTime.now(),
      result: result,
      challengePassed: challengePassed,
    );

    _history.removeWhere((r) => r.round == record.round && _isSameDay(r.date, record.date));
    _history.add(record);
    
    await _saveHistory(); // Persistência Local
    _syncToExternalDatabase(record); // Persistência Externa

    if (_isSchedulerRunning && !manual && _currentRound < _settingsService.getSettings().numberOfRounds) {
      final interval = _settingsService.getSettings().intervalInMinutes;
      _scheduleNextRound(Duration(minutes: interval));
    } else if (_isSchedulerRunning && !manual && _currentRound >= _settingsService.getSettings().numberOfRounds) {
      _nextRoundTime = null;
    }

    notifyListeners();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  void _resetIfNewDay() {
    if (_history.isNotEmpty) {
      final lastRecordDate = _history.last.date;
      final now = DateTime.now();
      if (!_isSameDay(lastRecordDate, now)) {
        _history = [];
        _currentRound = 0;
        _saveHistory();
        notifyListeners();
      }
    }
  }

  void startScheduler() {
    _resetIfNewDay();
    if (_isSchedulerRunning) return;

    _isSchedulerRunning = true;
    _currentRound = _getTodayHistory().map((r) => r.round).fold(0, (max, r) => r > max ? r : max);

    notifyListeners();
    _scheduleNextAutomaticRound();
  }

  void _scheduleNextAutomaticRound() {
    if (!_isSchedulerRunning) return;

    final settings = _settingsService.getSettings();
    final interval = Duration(minutes: settings.intervalInMinutes);

    bool shouldRunNow = false;
    if (_currentRound == 0) {
      shouldRunNow = true;
    }

    _timer?.cancel();

    if (_currentRound < settings.numberOfRounds) {
      Duration delay = shouldRunNow ? const Duration(seconds: 5) : interval;

      if (!shouldRunNow && _history.isNotEmpty) {
        final nextScheduled = lastRecord!.timestamp.add(interval);
        if (DateTime.now().isAfter(nextScheduled)) {
          delay = const Duration(seconds: 10);
        } else {
          delay = nextScheduled.difference(DateTime.now());
        }
      }

      _nextRoundTime = DateTime.now().add(delay);
      notifyListeners();

      _timer = Timer(delay, () {
        if (_isSchedulerRunning && _currentRound < settings.numberOfRounds) {
          runAttendanceRound();
        } else {
          stopScheduler();
        }
      });
    } else {
      stopScheduler();
    }
  }

  void stopScheduler() {
    _timer?.cancel();
    _timer = null;
    _isSchedulerRunning = false;
    _nextRoundTime = null;
    notifyListeners();
  }

  void _scheduleNextRound(Duration after) {
    if (!_isSchedulerRunning) return;
    _nextRoundTime = DateTime.now().add(after);
    notifyListeners();
    Future.microtask(() => _scheduleNextAutomaticRound());
  }

  Future<void> runSingleAttendanceRound() async {
    _isProcessing = true;
    notifyListeners();
    await runAttendanceRound(manual: true);
    _isProcessing = false;
    notifyListeners();
  }

  Future<bool> _triggerLivenessChallenge() async {
    _challengeCompleter = Completer<bool>();
    isChallengeActive.value = true;
    bool result = await _challengeCompleter!.future;
    isChallengeActive.value = false;
    return result;
  }

  void completeChallenge(bool success) {
    if (_challengeCompleter != null && !_challengeCompleter!.isCompleted) {
      _challengeCompleter!.complete(success);
    }
  }

  // Exportar e Compartilhar CSV 
  Future<void> exportAndShareCsv() async {
    final todayHistory = _getTodayHistory();
    if (todayHistory.isEmpty) {
      throw Exception("Nenhum dado de hoje para exportar.");
    }

    final header = [
      'Matrícula', 
      'Nome do Aluno', 
      'Data', 
      'Rodada', 
      'Status', 
      'Horário do Registro', 
      'Método de Validação'
    ];
    List<List<String>> rows = [
      header,
      ...todayHistory.map((r) => r.toCsvRow())
    ];
    String csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    try {
      // Salva em diretório temporário para facilitar o compartilhamento
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final fileName = "chamada_$dateStr.csv";
      final path = "${directory.path}/$fileName";
      
      final file = File(path);
      await file.writeAsString(csv);

      // Usa Share Plus para compartilhar o arquivo (WhatsApp, E-mail, etc)
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Relatório de Chamada - $dateStr',
      );
    } catch (e) {
      debugPrint("Erro ao exportar/compartilhar: $e");
      throw Exception("Erro ao gerar arquivo: $e");
    }
  }

  String getRoundStatus(int roundNumber) {
    _resetIfNewDay();
    final todayHistory = _getTodayHistory();
    final record = todayHistory.where((r) => r.round == roundNumber).firstOrNull;

    if (record != null) return record.result;

    final settings = _settingsService.getSettings();
    if (roundNumber > settings.numberOfRounds) return "Inválida";
    if (!_isSchedulerRunning && _currentRound < roundNumber) return "Agendador Inativo";
    
    if (_isSchedulerRunning) {
      if (_currentRound >= roundNumber && nextRoundTime != null && roundNumber > _currentRound) return "A iniciar";
      if (_currentRound >= roundNumber) return "Não registrada";
      if (roundNumber == _currentRound + 1 && nextRoundTime != null) return "A iniciar";
      if (roundNumber > _currentRound + 1) return "Agendada";
    }

    return "Pendente";
  }

  List<Map<String, dynamic>> getAllRoundsStatus() {
    final settings = _settingsService.getSettings();
    final List<Map<String, dynamic>> roundsStatus = [];
    for (int i = 1; i <= settings.numberOfRounds; i++) {
      roundsStatus.add({'round': i, 'status': getRoundStatus(i)});
    }
    return roundsStatus;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}