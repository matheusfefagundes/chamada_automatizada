import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/attendance_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _roundsController;
  late TextEditingController _intervalController;
  late bool _isSchedulerRunning;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>().getSettings();
    _isSchedulerRunning = context.read<AttendanceService>().isSchedulerRunning;
    _roundsController = TextEditingController(text: settings.numberOfRounds.toString());
    _intervalController = TextEditingController(text: settings.intervalInMinutes.toString());
  }

  void _saveSettings() {
    final settings = AppSettings(
      numberOfRounds: int.tryParse(_roundsController.text) ?? 4,
      intervalInMinutes: int.tryParse(_intervalController.text) ?? 1,
    );
    context.read<SettingsService>().saveSettings(settings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas! Elas serão aplicadas na próxima vez que o agendador iniciar.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Agendador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Ativar chamada automática'),
            value: _isSchedulerRunning,
            onChanged: (bool value) {
              if (value) {
                context.read<AttendanceService>().startScheduler();
              } else {
                context.read<AttendanceService>().stopScheduler();
              }
              setState(() {
                _isSchedulerRunning = value;
              });
            },
          ),
          const Divider(height: 30),
          const Text('Parâmetros da Chamada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _roundsController,
            decoration: const InputDecoration(
              labelText: 'Número de Rodadas',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _intervalController,
            decoration: const InputDecoration(
              labelText: 'Intervalo entre Rodadas (minutos)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Salvar Configurações'),
          ),
        ],
      ),
    );
  }
}