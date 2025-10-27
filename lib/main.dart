import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importar para inicialização

import 'screens/onboarding_screen.dart';
import 'screens/home_scaffold.dart';
import 'services/attendance_service.dart';
import 'services/settings_service.dart';

void main() async {
  // Garante que os bindings do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // ***** CORRIGIDO *****
  // Inicializa os dados de formatação de data/hora para o locale padrão
  // O segundo argumento foi removido.
  await initializeDateFormatting();
  // *********************

  // Inicializa os serviços e o SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);
  // Passa settingsService E prefs para AttendanceService
  final attendanceService = AttendanceService(settingsService, prefs);

  runApp(
    MultiProvider(
      providers: [
        // Usa .value para instâncias já criadas
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: attendanceService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chamada Automática',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white), // Ajuste opcional
        ),
        // ***** CORRIGIDO *****
        // Usar CardThemeData em vez de CardTheme
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordas arredondadas
          margin: const EdgeInsets.symmetric(vertical: 8), // Margem padrão
        ),
        // *********************
        chipTheme: ChipThemeData(
          // Estilo padrão para Chips
          backgroundColor: Colors.grey.shade300,
          labelStyle: TextStyle(color: Colors.grey.shade800),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade400, width: 0.5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo, // Cor de fundo
              foregroundColor: Colors.white, // Cor do texto/ícone
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 24), // Ajuste padding
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold) // Estilo do texto
              ),
        ),
        // Adicionar um tema para SnackBar para consistência
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey.shade800,
          contentTextStyle: const TextStyle(color: Colors.white),
          actionTextColor: Colors.indigo.shade200,
          behavior: SnackBarBehavior.floating, // Flutuante fica melhor
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          // Decide qual tela mostrar com base no cadastro do aluno
          return settingsService.getStudent() == null
              ? const OnboardingScreen()
              : const HomeScaffold();
        },
      ),
    );
  }
}

