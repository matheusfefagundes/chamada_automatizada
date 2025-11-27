import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceService = Provider.of<AttendanceService>(context);
    final history = attendanceService.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Hoje'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share), // Ícone alterado para Share
            tooltip: 'Exportar e Compartilhar CSV',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                // Chama o método atualizado que abre o menu de compartilhamento
                await attendanceService.exportAndShareCsv();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text('Nenhuma rodada registrada hoje.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                final isPresent = record.result == 'Presente';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPresent ? Colors.green : Colors.red,
                      child: Text(
                        record.round.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      'Rodada ${record.round}: ${record.result}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'Horário: ${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}'),
                  ),
                );
              },
            ),
    );
  }
}