import 'package:flutter/material.dart';
import '../../models/guardian_model.dart';
import '../../models/player_model.dart';
import '../asistencias/asistencia_hijo_screen.dart';
import '../payments/pagos_hijo_screen.dart';
import '../matches/partidos_hijo_screen.dart';
import '../resultados/resultados_hijo_screen.dart';

class ApoderadoHomeScreen extends StatefulWidget {
  final GuardianModel guardian;
  final List<PlayerModel> hijos;

  const ApoderadoHomeScreen({Key? key, required this.guardian, required this.hijos}) : super(key: key);

  @override
  State<ApoderadoHomeScreen> createState() => _ApoderadoHomeScreenState();
}

class _ApoderadoHomeScreenState extends State<ApoderadoHomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    AsistenciaHijoScreen(hijos: widget.hijos),
    PagosHijoScreen(hijos: widget.hijos),
    PartidosHijoScreen(hijos: widget.hijos),
    ResultadosHijoScreen(hijos: widget.hijos),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, ${widget.guardian.nombreCompleto}'),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              // Implementa la lógica de logout aquí
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Asistencia'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Pagos'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Partidos'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Resultados'),
        ],
      ),
    );
  }
}