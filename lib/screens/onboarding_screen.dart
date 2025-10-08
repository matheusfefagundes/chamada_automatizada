// screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/student.dart';
import '../services/settings_service.dart';
import 'home_scaffold.dart';

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

  Future<void> _requestPermissionsAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Solicita todas as permissões necessárias
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.microphone,
      Permission.manageExternalStorage, // Para salvar CSV
    ].request();

    // Verifica se as permissões mais importantes foram concedidas
    if (statuses[Permission.location]!.isGranted &&
        statuses[Permission.bluetoothScan]!.isGranted) {
      final student = Student(
        id: _idController.text,
        name: _nameController.text,
        className: _classController.text,
      );
      await Provider.of<SettingsService>(context, listen: false).saveStudent(student);
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScaffold()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As permissões de Localização e Bluetooth são obrigatórias para o funcionamento do app.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro e Permissões')),
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
                  'Primeiro, preencha seus dados e conceda as permissões para que o app funcione corretamente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: 'Matrícula', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _classController,
                  decoration: const InputDecoration(labelText: 'Turma', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Conceder Permissões e Salvar'),
                  onPressed: _requestPermissionsAndSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

