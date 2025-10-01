import 'package:flutter/material.dart';
import '../services/scheduler.dart';

class CsvScreen extends StatelessWidget {
  const CsvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SchedulerService scheduler = SchedulerService();
    final csv = scheduler.buildCsv(turma: "TURMA101", name: "Aluno");

    return Scaffold(
      appBar: AppBar(title: const Text("Exportar CSV (preview)")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: SelectableText(csv.isNotEmpty ? csv : "Nenhum registro para exportar ainda."),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // In protótipo N2 apenas mostra mensagem; em N3 podemos salvar/share
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preview gerado. Em N3 exporta para arquivo/compartilha.")));
        },
        label: const Text("Gerar preview"),
        icon: const Icon(Icons.file_present),
      ),
    );
  }
}