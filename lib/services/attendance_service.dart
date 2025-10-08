// services/attendance_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/attendance_record.dart';
import 'settings_service.dart';
import 'sensor_service.dart'; // Importa o novo serviço de sensores

class AttendanceService with ChangeNotifier {
  final SettingsService _settingsService;
  final SensorService _sensorService = SensorService(); // Instancia o serviço de sensores
  Timer? _timer;

  // Notificador para o Liveness Challenge
  final ValueNotifier<bool> isChallengeActive = ValueNotifier(false);
  Completer<bool>? _challengeCompleter;

  List<AttendanceRecord> _history = [];
  bool _isSchedulerRunning = false;
  DateTime? _nextRoundTime;
  int _currentRound = 0;

  List<AttendanceRecord> get history => _history;
  bool get isSchedulerRunning => _isSchedulerRunning;
  DateTime? get nextRoundTime => _nextRoundTime;
  AttendanceRecord? get lastRecord => _history.isEmpty ? null : _history.last;

  AttendanceService(this._settingsService);

  void startScheduler() {
    if (_isSchedulerRunning) return;
    _isSchedulerRunning = true;
    _currentRound = 0;
    _history = [];
    
    // A primeira rodada começa após um curto intervalo para o usuário se preparar
    _scheduleNextRound(const Duration(seconds: 15)); 
    _timer = Timer(const Duration(seconds: 15), _runFirstRound);

    notifyListeners();
  }
  
  void _runFirstRound() async {
    await runAttendanceRound();
    if(!_isSchedulerRunning) return;

    final interval = _settingsService.getSettings().intervalInMinutes;
    _timer = Timer.periodic(Duration(minutes: interval), (timer) {
      if (_currentRound >= _settingsService.getSettings().numberOfRounds -1) {
        stopScheduler();
      } else {
        runAttendanceRound();
      }
    });
  }


  void stopScheduler() {
    _timer?.cancel();
    _isSchedulerRunning = false;
    _nextRoundTime = null;
    notifyListeners();
  }

  void _scheduleNextRound(Duration after) {
      _nextRoundTime = DateTime.now().add(after);
      notifyListeners();
  }

  Future<void> runAttendanceRound({bool manual = false}) async {
    final student = _settingsService.getStudent();
    if (student == null) return;
    
    if (!manual) {
      _currentRound++;
    }

    // 1. Dispara o Liveness Challenge e aguarda a resposta do usuário
    final challengePassed = await _triggerLivenessChallenge();

    // 2. Coleta os sinais reais dos sensores
    final signals = await _collectRealSignals(challengePassed);

    // 3. Calcula o score
    final score = _computePresenceScore(signals);

    // 4. Registra a presença
    final record = AttendanceRecord(
      studentId: student.id,
      studentName: student.name,
      date: DateTime.now(),
      round: manual ? _history.length + 1 : _currentRound,
      timestamp: DateTime.now(),
      presenceScore: score,
      result: score >= 50 ? 'Presente' : 'Ausente',
      ssidDetected: signals['ssid_detected'] != null,
      bleCount: signals['ble_count'] as int,
      accelVariance: signals['accel_variance'] as double,
      audioRms: signals['audio_rms'] as double,
      challengePassed: challengePassed,
    );

    _history.add(record);
    
    if (_isSchedulerRunning && !manual) {
      final interval = _settingsService.getSettings().intervalInMinutes;
      _scheduleNextRound(Duration(minutes: interval));
    }
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

  // Coleta dados REAIS dos sensores
  Future<Map<String, dynamic>> _collectRealSignals(bool challengeResult) async {
    final results = await Future.wait([
      _sensorService.getWifiSsid(),
      _sensorService.scanBleDevices(),
      _sensorService.getAccelerometerVariance(),
      _sensorService.getAudioRms(),
    ]);

    return {
      'ssid_detected': results[0],
      'ble_count': results[1],
      'accel_variance': results[2],
      'audio_rms': results[3],
      'challenge_passed': challengeResult,
    };
  }

  int _computePresenceScore(Map<String, dynamic> signals) {
    double score = 0;
    
    // SSID da instituição (exemplo: 'eduroam', 'uni-wifi', etc.)
    final targetSsid = 'eduroam'; // Defina o SSID alvo aqui
    if (signals['ssid_detected'] != null && (signals['ssid_detected'] as String).toLowerCase().contains(targetSsid)) {
      score += 30;
    }
    int bleCount = signals['ble_count'];
    score += (bleCount > 10 ? 10 : bleCount) * 2;
    double accelVariance = signals['accel_variance'];
    if (accelVariance < 0.05) score += 15;
    else if (accelVariance < 0.5) score += 7;
    double audioRms = signals['audio_rms'];
    if (audioRms > 15.0 && audioRms < 40.0) score += 20;
    else if (audioRms >= 40.0) score += 10;
    if (signals['challenge_passed'] == true) score += 15;

    return score.clamp(0, 100).toInt();
  }

  Future<String?> exportToCsv() async {
    if (_history.isEmpty) return "Nenhum dado para exportar.";
    final header = ['student_id', 'student_name', 'date', 'rodada', 'timestamp', 'presence_score', 'result', 'ssid_detected', 'ble_count', 'accel_variance', 'audio_rms', 'challenge_passed'];
    List<List<String>> rows = [header, ..._history.map((r) => r.toCsvRow())];
    String csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    try {
      if (await Permission.manageExternalStorage.request().isGranted) {
        final directory = await getExternalStorageDirectory();
        final path = "${directory?.path}/chamada_${DateTime.now().millisecondsSinceEpoch}.csv";
        final file = File(path);
        await file.writeAsString(csv);
        return path;
      }
      return "Permissão de armazenamento negada.";
    } catch (e) {
      return "Erro ao salvar arquivo: $e";
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorService.dispose();
    super.dispose();
  }
}

