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

  // NOVO: Método para converter para Map (JSON)
  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'date': date.toIso8601String(), // Salvar data como ISO string
        'round': round,
        'timestamp':
            timestamp.toIso8601String(), // Salvar timestamp como ISO string
        'result': result,
        'challengePassed': challengePassed,
      };

  // NOVO: Factory constructor para criar a partir de Map (JSON)
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        date: DateTime.parse(
            json['date'] as String), // Converter string ISO para DateTime
        round: json['round'] as int,
        timestamp: DateTime.parse(
            json['timestamp'] as String), // Converter string ISO para DateTime
        result: json['result'] as String,
        challengePassed: json['challengePassed'] as bool,
      );

  List<String> toCsvRow() {
    return [
      studentId,
      studentName,
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}", // Alterado para YYYY-MM-DD
      round.toString(),
      result == 'Presente' ? 'P' : 'F', // Status P/F
      timestamp.toIso8601String(),
      '', // notes
      'CHALLENGE_DIALOG' // validation_method
    ];
  }
}
