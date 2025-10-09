import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../services/settings_service.dart';
import '../models/student.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceService = context.watch<AttendanceService>();
    final settingsService = context.watch<SettingsService>();
    final Student? student = settingsService.getStudent();

    final nextRoundTime = attendanceService.nextRoundTime;
    final lastRecord = attendanceService.lastRecord;
    final isSchedulerRunning = attendanceService.isSchedulerRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${student?.name ?? 'Aluno'}!',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Turma: ${student?.className ?? 'N/A'}'),
                    Text('Matrícula: ${student?.id ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Status da Chamada',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    if (isSchedulerRunning)
                      nextRoundTime != null
                          ? Text(
                              'Próxima rodada: ${TimeOfDay.fromDateTime(nextRoundTime).format(context)}',
                              style: const TextStyle(fontSize: 16),
                            )
                          : const Text('Todas as rodadas concluídas.',
                              style: TextStyle(fontSize: 16))
                    else
                      const Text('O agendador não está ativo.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    if (lastRecord != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Último resultado: '),
                          Text(
                            lastRecord.result,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: lastRecord.result == 'Presente'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text('Nenhum registro de chamada hoje.'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: attendanceService.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white))
                  : const Icon(Icons.sensors),
              label: Text(attendanceService.isProcessing
                  ? 'Processando...'
                  : 'Forçar Rodada Agora'),
              onPressed: attendanceService.isProcessing
                  ? null
                  : () {
                      context
                          .read<AttendanceService>()
                          .runSingleAttendanceRound();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Iniciando rodada... Fique atento ao desafio!')),
                      );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}