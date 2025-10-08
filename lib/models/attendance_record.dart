class AttendanceRecord {
  final String studentId;
  final String studentName;
  final DateTime date;
  final int round;
  final DateTime timestamp;
  final int presenceScore;
  final String result;
  final bool ssidDetected;
  final int bleCount;
  final double accelVariance;
  final double audioRms;
  final bool challengePassed;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.round,
    required this.timestamp,
    required this.presenceScore,
    required this.result,
    required this.ssidDetected,
    required this.bleCount,
    required this.accelVariance,
    required this.audioRms,
    required this.challengePassed,
  });

  // Converte o registro para uma lista de strings para o CSV
  List<String> toCsvRow() {
    return [
      studentId,
      studentName,
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
      round.toString(),
      timestamp.toIso8601String(),
      presenceScore.toString(),
      result,
      ssidDetected.toString(),
      bleCount.toString(),
      accelVariance.toStringAsFixed(2),
      audioRms.toStringAsFixed(2),
      challengePassed.toString(),
    ];
  }
}
