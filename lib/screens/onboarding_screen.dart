import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../services/settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _classController = TextEditingController();

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final student = Student(
      id: _idController.text,
      name: _nameController.text,
      className: _classController.text,
    );
    await Provider.of<SettingsService>(context, listen: false)
        .saveStudent(student);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro do Aluno')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 80, color: Colors.indigo),
                const SizedBox(height: 20),
                const Text(
                  'Bem-vindo!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Preencha seus dados para começar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(
                        labelText: 'Matrícula', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _classController,
                    decoration: const InputDecoration(
                        labelText: 'Turma', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Salvar'),
                  onPressed: _saveStudent,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}