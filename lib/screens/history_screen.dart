import 'package:flutter/material.dart';
import '../services/scheduler.dart';
import '../models/attendance_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SchedulerService _scheduler = SchedulerService();

  @override
  void initState() {
    super.initState();
    // listen to notifiers to refresh UI
    _scheduler.currentRoundNotifier.addListener(_onChange);
    _scheduler.roundActiveNotifier.addListener(_onChange);
  }

  @override
  void dispose() {
    _scheduler.currentRoundNotifier.removeListener(_onChange);
    _scheduler.roundActiveNotifier.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final records = _scheduler.records;
    return Scaffold(
      appBar: AppBar(title: const Text("Histórico")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: records.isEmpty
            ? const Center(child: Text("Nenhum registro ainda."))
            : ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, idx) {
                  final AttendanceRecord r = records[idx];
                  return Card(
                    child: ListTile(
                      title: Text("Rodada ${r.roundNumber} — ${r.statusString()}"),
                      subtitle: Text("Agendada: ${r.scheduledTime.toLocal().toIso8601String().split('T').join(' ')}\nEvid: ${r.evidencesString()}"),
                    ),
                  );
                },
              ),
      ),
    );
  }
}