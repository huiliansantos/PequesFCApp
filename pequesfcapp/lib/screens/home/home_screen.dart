import 'package:flutter/material.dart';
import '../players/player_list_screen.dart';
import '../guardians/guardians_list_screen.dart';
import '../payments/payment_management_screen.dart';
import '../matches/match_schedule_screen.dart';
import '../results/result_registration_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _adminScreens = [
    PlayerListScreen(),            // Gestión de jugadores
    GuardianListScreen(),          // Gestión de apoderados
    PaymentManagementScreen(),
    MatchScheduleScreen(),
    ResultRegistrationScreen(
      rival: '', // TODO: Provide appropriate rival value
      categoria: '', // TODO: Provide appropriate categoria value
      fecha: DateTime.now(), // TODO: Provide appropriate fecha value
    ),
    SettingsScreen(),
  ];

  static final List<BottomNavigationBarItem> _adminNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Jugadores'),
    BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label: 'Apoderados'),
    BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Pagos'),
    BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Partidos'),
    BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Resultados'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _adminScreens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _adminNavItems,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}