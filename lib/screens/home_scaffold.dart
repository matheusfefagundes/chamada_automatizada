import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import 'challenge_dialog.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});
  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Ouve o notificador do desafio para exibir o diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceService = context.read<AttendanceService>();
      attendanceService.isChallengeActive.addListener(_showChallengeIfNeeded);
    });
  }

  @override
  void dispose() {
    // É importante remover o listener para evitar memory leaks
    if(mounted){
       context.read<AttendanceService>().isChallengeActive.removeListener(_showChallengeIfNeeded);
    }
    super.dispose();
  }

  void _showChallengeIfNeeded() {
    final attendanceService = context.read<AttendanceService>();
    // Garante que o diálogo não seja mostrado sobre outro
    if (attendanceService.isChallengeActive.value && ModalRoute.of(context)?.isCurrent == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ChallengeDialog(
            duration: 10, // Duração do desafio em segundos
            onComplete: (success) {
              // Informa ao serviço se o desafio foi completado com sucesso ou não
              attendanceService.completeChallenge(success);
            },
          );
        },
      );
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Configurações'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

