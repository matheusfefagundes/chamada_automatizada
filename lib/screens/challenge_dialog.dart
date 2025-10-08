import 'dart:async';
import 'package:flutter/material.dart';

class ChallengeDialog extends StatefulWidget {
  final int duration;
  final Function(bool) onComplete;

  const ChallengeDialog({
    super.key,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<ChallengeDialog> {
  late int _countdown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _countdown = widget.duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        Navigator.of(context).pop();
        widget.onComplete(false); // Falhou por tempo
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('! Desafio de Presença !'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Clique no botão abaixo em:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '$_countdown',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
            widget.onComplete(true); // Sucesso
          },
          child: const Text('CONFIRMAR PRESENÇA'),
        ),
      ],
    );
  }
}
