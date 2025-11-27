import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart'; 

import 'screens/onboarding_screen.dart';
import 'screens/home_scaffold.dart';
import 'services/attendance_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa dados de formatação de data
  await initializeDateFormatting();

  // Inicializa o Firebase (Nota 10)
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase inicializado com sucesso.");
  } catch (e) {
    debugPrint("Erro ao inicializar Firebase: $e");
    // O app continua funcionando mesmo sem Firebase (modo offline/fallback)
  }

  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);
  final attendanceService = AttendanceService(settingsService, prefs);

  runApp(
    MultiProvider(
      providers: [
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
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey.shade300,
          labelStyle: TextStyle(color: Colors.grey.shade800),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade400, width: 0.5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey.shade800,
          contentTextStyle: const TextStyle(color: Colors.white),
          actionTextColor: Colors.indigo.shade200,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          return settingsService.getStudent() == null
              ? const OnboardingScreen()
              : const HomeScaffold();
        },
      ),
    );
  }
}