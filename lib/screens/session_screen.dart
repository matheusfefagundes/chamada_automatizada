import 'package:flutter/material.dart';
import '../services/scheduler.dart';
import 'dart:async';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final SchedulerService _scheduler = SchedulerService();
  int _remaining = 0;
  bool _challengeActive = false;
  final String studentId = "2024001"; // ID fixo protótipo
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _scheduler.roundActiveNotifier.addListener(_onRoundActive);
    _onRoundActive();
  }

  @override
  void dispose() {
    _scheduler.roundActiveNotifier.removeListener(_onRoundActive);
    _timer.cancel();
    super.dispose();
  }

  void _onRoundActive() {
    final active = _scheduler.roundActiveNotifier.value;
    if (active) {
      setState(() {
        _challengeActive = true;
        _remaining = _scheduler.challengeSeconds;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _remaining--;
        });
        if (_remaining <= 0) {
          t.cancel();
          _challengeActive = false;
        }
      });
    } else {
      setState(() {
        _challengeActive = false;
        _remaining = 0;
      });
    }
  }

  void _confirmPresence() {
    _scheduler.completeChallenge(studentId: studentId);
    setState(() {
      _challengeActive = false;
      _remaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Presença confirmada!")));
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = _scheduler.currentRoundNotifier.value;
    final active = _scheduler.roundActiveNotifier.value;

    return Scaffold(
      appBar: AppBar(title: const Text("Sessão")),
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
                    Text("Rodada: $currentRound / ${_scheduler.rounds}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(active
                        ? "Rodada ATIVA — toque para confirmar presença"
                        : "Aguardando próxima rodada"),
                    if (_challengeActive)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text("Tempo restante: $_remaining s", style: const TextStyle(fontSize: 16)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_challengeActive)
              ElevatedButton(
                onPressed: _confirmPresence,
                child: const Text("Confirmar Presença"),
              ),
          ],
        ),
      ),
    );
  }
}
