import 'package:flutter/material.dart';
import '../services/scheduler.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final SchedulerService _scheduler = SchedulerService();
  late TextEditingController _intervalSecController;
  late TextEditingController _roundsController;

  @override
  void initState() {
    super.initState();
    _intervalSecController = TextEditingController(text: _scheduler.interval.inSeconds.toString());
    _roundsController = TextEditingController(text: _scheduler.rounds.toString());
  }

  @override
  void dispose() {
    _intervalSecController.dispose();
    _roundsController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final sec = int.tryParse(_intervalSecController.text) ?? 30;
    final rounds = int.tryParse(_roundsController.text) ?? 4;
    setState(() {
      _scheduler.interval = Duration(seconds: sec);
      _scheduler.rounds = rounds;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configurações salvas (aplicam em próxima sessão)")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              controller: _roundsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Número de rodadas"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _intervalSecController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Intervalo entre rodadas (s) — para teste"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _saveConfig, child: const Text("Salvar")),
            const SizedBox(height: 20),
            const Text("Nota: em produção ajuste para 3000s (~50min)."),
          ],
        ),
      ),
    );
  }
}
