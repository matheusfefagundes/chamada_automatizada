import 'dart:async';
import '../models/attendance_record.dart';
import '../models/evidence.dart';
import 'package:flutter/foundation.dart';

class SchedulerService {
  static final SchedulerService _instance = SchedulerService._internal();
  factory SchedulerService() => _instance;
  SchedulerService._internal();

  int rounds = 4;
  Duration interval = const Duration(seconds: 30); // teste: 30s (ajuste 50min produção)

  final List<AttendanceRecord> _records = [];
  List<AttendanceRecord> get records => List.unmodifiable(_records);

  Timer? _periodicTimer;
  int _currentRound = 0;

  final ValueNotifier<int> currentRoundNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> roundActiveNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime?> scheduledTimeNotifier = ValueNotifier<DateTime?>(null);

  final int challengeSeconds = 10; // tempo para responder

  // Start scheduling
  void start({DateTime? startTime}) {
    stop();
    _records.clear();
    _currentRound = 0;
    currentRoundNotifier.value = 0;
    roundActiveNotifier.value = false;

    scheduledTimeNotifier.value = startTime ?? DateTime.now();

    Future.delayed(const Duration(milliseconds: 500), () => _triggerRound());

    _periodicTimer = Timer.periodic(interval, (t) {
      if (_currentRound >= rounds) {
        t.cancel();
        roundActiveNotifier.value = false;
        return;
      }
      _triggerRound();
    });
  }

  void _triggerRound() {
    if (_currentRound >= rounds) return;
    _currentRound++;
    currentRoundNotifier.value = _currentRound;

    final scheduled = scheduledTimeNotifier.value != null
        ? scheduledTimeNotifier.value!.add(Duration(seconds: interval.inSeconds * (_currentRound - 1)))
        : DateTime.now();
    scheduledTimeNotifier.value = scheduled;

    // Ativa rodada e challenge automático
    roundActiveNotifier.value = true;

    // Timer do challenge
    Future.delayed(Duration(seconds: challengeSeconds), () {
      if (roundActiveNotifier.value) {
        _finalizeRoundAbsent(scheduled);
      }
    });
  }

  // Chamado quando aluno confirma presença
  void completeChallenge({required String studentId}) {
    if (!roundActiveNotifier.value) return;

    final scheduled = scheduledTimeNotifier.value ?? DateTime.now();
    final record = AttendanceRecord(
      studentId: studentId,
      date: DateTime.now(),
      roundNumber: _currentRound,
      scheduledTime: scheduled,
      recordedTime: DateTime.now(),
      status: AttendanceStatus.present,
      evidences: [Evidence(type: "challenge", detail: "clicou")],
    );
    _records.add(record);
    roundActiveNotifier.value = false;
  }

  void _finalizeRoundAbsent(DateTime scheduled) {
    final record = AttendanceRecord(
      studentId: "2024001",
      date: DateTime.now(),
      roundNumber: _currentRound,
      scheduledTime: scheduled,
      recordedTime: DateTime.now(),
      status: AttendanceStatus.absent,
      evidences: [Evidence(type: "challenge", detail: "não respondeu")],
    );
    _records.add(record);
    roundActiveNotifier.value = false;
  }

  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    roundActiveNotifier.value = false;
    _currentRound = 0;
    currentRoundNotifier.value = 0;
  }

  String buildCsv({required String turma, required String name}) {
    final sb = StringBuffer();
    sb.writeln("student_id,date,round_number,scheduled_time,recorded_time,status,evidences");
    for (var r in _records) {
      sb.writeln(r.toCsv());
    }
    return sb.toString();
  }
}
