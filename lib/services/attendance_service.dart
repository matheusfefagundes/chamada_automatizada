import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/attendance_record.dart';
import 'settings_service.dart';

class AttendanceService with ChangeNotifier {
  final SettingsService _settingsService;
  Timer? _timer;

  final ValueNotifier<bool> isChallengeActive = ValueNotifier(false);
  Completer<bool>? _challengeCompleter;

  List<AttendanceRecord> _history = [];
  bool _isSchedulerRunning = false;
  bool _isProcessing = false;
  DateTime? _nextRoundTime;
  int _currentRound = 0;

  List<AttendanceRecord> get history => _history;
  bool get isSchedulerRunning => _isSchedulerRunning;
  bool get isProcessing => _isProcessing;
  DateTime? get nextRoundTime => _nextRoundTime;
  AttendanceRecord? get lastRecord => _history.isEmpty ? null : _history.last;

  AttendanceService(this._settingsService);

  void startScheduler() {
    if (_isSchedulerRunning) return;
    _isSchedulerRunning = true;
    _currentRound = 0;
    _history = [];
    notifyListeners();

    // A primeira rodada começa após um curto intervalo para simulação
    const initialDelay = Duration(seconds: 15);
    final interval =
        Duration(minutes: _settingsService.getSettings().intervalInMinutes);

    _scheduleNextRound(initialDelay);

    _timer = Timer(initialDelay, () {
      // Executa a primeira ronda
      runAttendanceRound();

      // Agenda as rondas subsequentes
      _timer = Timer.periodic(interval, (timer) {
        if (_currentRound >= _settingsService.getSettings().numberOfRounds) {
          stopScheduler();
        } else {
          runAttendanceRound();
        }
      });
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

  Future<void> runSingleAttendanceRound() async {
    _isProcessing = true;
    notifyListeners();
    await runAttendanceRound(manual: true);
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> runAttendanceRound({bool manual = false}) async {
    final student = _settingsService.getStudent();
    if (student == null) return;

    if (!manual) {
      _currentRound++;
    }

    final challengePassed = await _triggerLivenessChallenge();

    final record = AttendanceRecord(
      studentId: student.id,
      studentName: student.name,
      date: DateTime.now(),
      round: manual ? _history.length + 1 : _currentRound,
      timestamp: DateTime.now(),
      result: challengePassed ? 'Presente' : 'Ausente',
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

  Future<String?> exportToCsv() async {
    if (_history.isEmpty) return "Nenhum dado para exportar.";
    final header = [
      'student_id',
      'student_name',
      'date',
      'rodada',
      'timestamp',
      'status',
      'notes',
      'validation_method'
    ];
    List<List<String>> rows = [
      header,
      ..._history.map((r) => [
            r.studentId,
            r.studentName,
            '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}',
            r.round.toString(),
            r.result == 'Presente' ? 'P' : 'F',
            r.timestamp.toIso8601String(),
            '', // notes
            'CHALLENGE_DIALOG' // validation_method
          ])
    ];
    String csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          "${directory.path}/chamada_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csv);
      return path;
    } catch (e) {
      debugPrint("Erro ao salvar arquivo: $e");
      return "Erro ao salvar arquivo: $e";
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
