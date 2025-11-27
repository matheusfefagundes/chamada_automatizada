import 'dart:async';
import 'dart:math'; // Import necessário para o Random
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
  // Variável para armazenar o alinhamento sorteado para esta rodada
  late MainAxisAlignment _randomAlignment;

  @override
  void initState() {
    super.initState();
    _countdown = widget.duration;
    
    // --- LÓGICA ANTIFRAUDE: UI RANDOMIZATION ---
    // Sorteia uma posição para o botão (Esquerda, Centro ou Direita)
    // Isso impede scripts que clicam em coordenadas fixas.
    final random = Random();
    final possibleAlignments = [
      MainAxisAlignment.start,  // Esquerda
      MainAxisAlignment.center, // Centro
      MainAxisAlignment.end     // Direita
    ];
    _randomAlignment = possibleAlignments[random.nextInt(possibleAlignments.length)];
    // -------------------------------------------

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        // Verifica se o widget ainda está montado antes de fechar
        if (mounted) {
          Navigator.of(context).pop();
          widget.onComplete(false); // Falhou por tempo
        }
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
    // Impede o fechamento ao clicar fora (barrierDismissible deve ser tratado no showDialog, 
    // mas o WillPopScope/PopScope ajuda com o botão voltar do Android)
    return PopScope(
      canPop: false, // Impede fechar com botão voltar
      child: AlertDialog(
        title: const Text('! Desafio de Presença !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para confirmar que você não é um robô, clique no botão abaixo em:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '$_countdown',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
        actions: [
          // Row que ocupa toda a largura disponível para permitir o movimento do botão
          Row(
            // Aplica o alinhamento aleatório definido no initState
            mainAxisAlignment: _randomAlignment,
            children: [
              ElevatedButton( // Mudado para ElevatedButton para maior visibilidade do alvo
                onPressed: () {
                  _timer?.cancel();
                  Navigator.of(context).pop();
                  widget.onComplete(true); // Sucesso
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ESTOU AQUI'), // Texto atualizado conforme sua descrição
              ),
            ],
          ),
        ],
      ),
    );
  }
}