import 'evidence.dart';

enum AttendanceStatus { present, absent, contested }

class AttendanceRecord {
  final String studentId;
  final DateTime date;
  final int roundNumber;
  final DateTime scheduledTime;
  final DateTime recordedTime;
  final AttendanceStatus status;
  final List<Evidence> evidences;

  AttendanceRecord({
    required this.studentId,
    required this.date,
    required this.roundNumber,
    required this.scheduledTime,
    required this.recordedTime,
    required this.status,
    required this.evidences,
  });

  String statusString() {
    switch (status) {
      case AttendanceStatus.present:
        return "PRESENT";
      case AttendanceStatus.absent:
        return "ABSENT";
      case AttendanceStatus.contested:
        return "CONTESTED";
    }
  }

  String evidencesString() {
    return evidences.map((e) => "${e.type}=${e.detail}").join(';');
  }

  String toCsv() {
    return "$studentId,${date.toIso8601String()},$roundNumber,"
        "${scheduledTime.toIso8601String()},${recordedTime.toIso8601String()},"
        "${statusString()},\"${evidencesString()}\"";
  }
}
