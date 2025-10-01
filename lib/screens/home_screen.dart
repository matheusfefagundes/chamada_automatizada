import 'package:flutter/material.dart';
import '../services/scheduler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SchedulerService _scheduler = SchedulerService();
  bool running = false;

  @override
  void initState() {
    super.initState();
    _scheduler.currentRoundNotifier.addListener(_onRoundChanged);
    _scheduler.roundActiveNotifier.addListener(_onRoundActiveChanged);
  }

  @override
  void dispose() {
    _scheduler.currentRoundNotifier.removeListener(_onRoundChanged);
    _scheduler.roundActiveNotifier.removeListener(_onRoundActiveChanged);
    super.dispose();
  }

  void _onRoundChanged() => setState(() {});
  void _onRoundActiveChanged() => setState(() {});

  void _start() {
    _scheduler.start();
    setState(() {
      running = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chamadas iniciadas (simulação: intervalo 30s).")),
    );
  }

  void _stop() {
    _scheduler.stop();
    setState(() {
      running = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chamadas paradas.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = _scheduler.currentRoundNotifier.value;
    final isActive = _scheduler.roundActiveNotifier.value;

    return Scaffold(
      appBar: AppBar(title: const Text("Chamada Automática")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text("Status da Sessão", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text("Rodada atual: $currentRound / ${_scheduler.rounds}"),
                    const SizedBox(height: 8),
                    Text(isActive ? "Rodada ativa — responda o challenge!" : "Aguardando próxima rodada"),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_scheduler.rounds, (i) {
                        final idx = i + 1;
                        final color = idx < currentRound ? Colors.green : (idx == currentRound && isActive ? Colors.orange : Colors.grey.shade400);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: CircleAvatar(radius: 10, backgroundColor: color),
                        );
                      }),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: running ? null : _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Iniciar chamadas"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: running ? _stop : null,
              icon: const Icon(Icons.stop),
              label: const Text("Parar chamadas"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/session'),
              child: const Text("Sessão (abrir)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              child: const Text("Histórico"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/config'),
              child: const Text("Configurações"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/csv'),
              child: const Text("Exportar CSV (preview)"),
            ),
            const SizedBox(height: 20),
            const Text("Observação: protótipo N2 — intervalos reduzidos para testes."),
          ],
        ),
      ),
    );
  }
}