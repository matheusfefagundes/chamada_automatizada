import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../services/settings_service.dart';
import '../models/student.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Helper para obter cor de fundo com base no status
  Color _getStatusBackgroundColor(String status) {
    status = status.toLowerCase();
    
    if (status == 'presente') {
      return Colors.green.shade100;
    }
    if (status.contains('ausente')) {
      return Colors.red.shade100;
    }
    if (status == 'fora do local') {
      return Colors.orange.shade100;
    }
    if (status == 'a iniciar' || status == 'agendada') {
      return Colors.blue.shade100;
    }
    if (status.contains('erro')) {
      return Colors.purple.shade100;
    }
    // Pendente, Não Registrada, Agendador Inativo, N/A
    return Colors.grey.shade300;
  }

   // Helper para obter cor do texto com base no status
  Color _getStatusTextColor(String status) {
    status = status.toLowerCase();
     // ***** CORRIGIDO: Adicionadas chaves {} *****
     if (status == 'presente') {
      return Colors.green.shade900;
     }
     if (status.contains('ausente')) {
      return Colors.red.shade900;
     }
     if (status == 'fora do local') {
      return Colors.orange.shade900;
     }
     if (status == 'a iniciar' || status == 'agendada') {
      return Colors.blue.shade900;
     }
     if (status.contains('erro')) {
      return Colors.purple.shade900;
     }
     // Pendente, Não Registrada, Agendador Inativo, N/A
     return Colors.grey.shade800;
  }

  // Helper para obter ícone com base no status
  IconData _getStatusIcon(String status) {
     status = status.toLowerCase();
     if (status == 'presente') {
      return Icons.check_circle_outline;
     }
     if (status.contains('ausente')) {
      return Icons.highlight_off_outlined;
     }
     if (status == 'fora do local') {
      return Icons.location_off_outlined;
     }
     if (status == 'a iniciar') {
      return Icons.hourglass_top_outlined;
     }
     if (status == 'agendada') {
      return Icons.schedule_outlined;
     }
     if (status.contains('erro')) {
      return Icons.error_outline;
     }
     // Pendente, Não Registrada, Agendador Inativo, N/A
     return Icons.pending_outlined;
  }

  @override
  Widget build(BuildContext context) {
    // Usar watch para reconstruir quando o AttendanceService notificar
    final attendanceService = context.watch<AttendanceService>();
    final settingsService = context.watch<SettingsService>();
    final Student? student = settingsService.getStudent();

    final nextRoundTime = attendanceService.nextRoundTime;
    final isSchedulerRunning = attendanceService.isSchedulerRunning;
    // Pega status de todas as rodadas CADA VEZ que o widget reconstrói
    final allRoundsStatus = attendanceService.getAllRoundsStatus();

    // Formatter para hora
    final timeFormatter = DateFormat.Hm(Localizations.localeOf(context).languageCode); // HH:mm


    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              isSchedulerRunning ? Icons.timer_outlined : Icons.timer_off_outlined,
              color: isSchedulerRunning ? Colors.white : Colors.white54,
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Turma: ${student?.className ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Matrícula: ${student?.id ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20), // Espaçamento

          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Status das Rodadas Hoje',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  // Exibição detalhada das rodadas
                  if (allRoundsStatus.isNotEmpty)
                    Wrap(
                      spacing: 8.0, // Espaço horizontal entre os chips
                      runSpacing: 8.0, // Espaço vertical entre as linhas
                      alignment: WrapAlignment.center, // Centraliza os chips
                      children: allRoundsStatus.map((roundInfo) {
                        final int roundNum = roundInfo['round'];
                        final String status = roundInfo['status'];
                        final DateTime? timestamp = roundInfo['timestamp'];

                        return Chip(
                          avatar: Icon(
                            _getStatusIcon(status),
                            color: _getStatusTextColor(status),
                            size: 18,
                          ),
                          label: Text(
                            'R$roundNum: $status${timestamp != null ? ' (${timeFormatter.format(timestamp)})' : ''}',
                            style: TextStyle(
                                color: _getStatusTextColor(status),
                                fontWeight: FontWeight.w500),
                          ),
                          backgroundColor: _getStatusBackgroundColor(status),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(16),
                             side: BorderSide(color: Colors.grey.shade400, width: 0.5)
                           ),
                        );
                      }).toList(),
                    )
                  else
                     const Text("Nenhuma rodada configurada."), // Caso não haja rodadas nas settings


                  const SizedBox(height: 20),
                  // Informações gerais do agendador
                  if (isSchedulerRunning) ...[ 
                     if (nextRoundTime != null)
                        Text(
                            'Próxima verificação: ${timeFormatter.format(nextRoundTime)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                      else
                        const Text('Todas as rodadas do dia concluídas.',
                             style: TextStyle(fontSize: 16))
                  ] else if (attendanceService.currentRound >= (settingsService.getSettings().numberOfRounds))
                      const Text('Todas as rodadas do dia concluídas.',
                           style: TextStyle(fontSize: 16))
                  else
                     const Text('O agendador não está ativo.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),


                  const SizedBox(height: 16),
                   // Mostrar distância apenas se disponível
                   ValueListenableBuilder<double?>(
                     valueListenable: attendanceService.currentDistance,
                     builder: (context, distance, child) {
                       if (distance != null) {
                         bool isInside = distance <= attendanceService.maxDistanceInMeters; // Acessar maxDistanceInMeters diretamente (torná-lo público ou usar getter)
                         return Text(
                           'Distância atual: ${distance.toStringAsFixed(1)} m ${isInside ? "(Dentro)" : "(Fora)"}',
                           style: TextStyle(fontSize: 14, color: isInside ? Colors.green.shade700: Colors.orange.shade800),
                         );
                       }
                       // Retornar um widget vazio se a distância for null
                       return const SizedBox.shrink();
                     },
                   ),

                ],
              ),
            ),
          ),
           const SizedBox(height: 24), // Espaço antes do botão

          // Botão Forçar Rodada
          ElevatedButton.icon(
            icon: attendanceService.isProcessing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                  )
                : const Icon(Icons.touch_app_outlined),
            label: Text(attendanceService.isProcessing
                ? 'Processando...'
                : 'Confirmar Presença Agora'), // Texto mais claro
            // Desabilita se estiver processando OU se todas as rodadas do dia já foram feitas
            onPressed: attendanceService.isProcessing || attendanceService.currentRound >= settingsService.getSettings().numberOfRounds
                ? null
                : () async {
                    // Mostrar um feedback de início
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Iniciando verificação... Fique atento ao desafio!'),
                          duration: Duration(seconds: 3),
                      ),
                    );
                    // Chamar a função
                    await attendanceService.runSingleAttendanceRound();
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20), // Espaço no final
        ],
      ),
    );
  }
}
