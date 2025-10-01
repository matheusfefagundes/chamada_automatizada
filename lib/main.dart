import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/session_screen.dart';
import 'screens/history_screen.dart';
import 'screens/config_screen.dart';
import 'screens/csv_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chamada Automática',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/session': (context) => const SessionScreen(),
        '/history': (context) => const HistoryScreen(),
        '/config': (context) => const ConfigScreen(),
        '/csv': (context) => const CsvScreen(),
      },
    );
  }
}
