class AttendanceRecord {
  final String studentId;
  final String studentName;
  final DateTime date;
  final int round;
  final DateTime timestamp;
  final String result;
  final bool challengePassed;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.round,
    required this.timestamp,
    required this.result,
    required this.challengePassed,
  });

  List<String> toCsvRow() {
    return [
      studentId,
      studentName,
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
      round.toString(),
      timestamp.toIso8601String(),
      result,
      challengePassed.toString(),
    ];
  }
}