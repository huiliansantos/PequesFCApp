import 'package:PequesFCApp/screens/results/resultados_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../players/player_list_screen.dart';
import '../guardians/guardians_list_screen.dart';
import '../guardians/guardian_form_screen.dart';
import '../players/player_form_screen.dart';
import '../payments/payment_management_screen.dart';
import '../matches/match_schedule_screen.dart';
import '../results/resultado_form_screen.dart';
import '../login/login_screen.dart';
import '../matches/match_form_screen.dart';
import '../asistencias/registro_asistencia_screen.dart';
import '../asistencias/reporte_asistencia_screen.dart';
import '../categorias/categoria_list_screen.dart';
import '../categorias/categoria_equipo_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final String? jugadorId; // Para apoderado, si quieres pasar el id del hijo
  const HomeScreen({super.key, required this.role, this.jugadorId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Pantallas para admin/profesor
  static final List<Widget> _adminScreens = [
    PlayerListScreen(),
    GuardianListScreen(),
    PaymentManagementScreen(),
    MatchScheduleScreen(),
    ResultadosListScreen(),
    CategoriaListScreen(), // Nueva pantalla de categorías
  
  ];

  // Pantallas para apoderado
  static final List<Widget> _apoderadoScreens = [
    PlayerListScreen(),
    GuardianListScreen(),
    PaymentManagementScreen(),
    MatchScheduleScreen(),
    ResultadosListScreen(),
    CategoriaListScreen(),
    // Reporte de asistencia solo para el hijo del apoderado
    ReporteAsistenciaScreen(jugadorId: ''), // Debes pasar el id real del hijo
  ];

  static final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Jugadores'),
    BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label: 'Apoderados'),
    BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Pagos'),
    BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Partidos'),
    BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Resultados'),
    BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Asistencia'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Elige las pantallas según el rol
    final screens = widget.role == 'apoderado'
        ? _apoderadoScreens
        : _adminScreens;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
              backgroundColor: Colors.grey,
              radius: 16,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email ?? "",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  widget.role == 'admin' ? 'Administrador' : widget.role,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_add, color: Color(0xFFD32F2F)),
                    title: const Text('Nuevo Jugador'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlayerFormScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.family_restroom, color: Color(0xFFD32F2F)),
                    title: const Text('Nuevo Apoderado'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GuardianFormScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sports_soccer, color: Color(0xFFD32F2F)),
                    title: const Text('Nuevo Partido'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MatchFormScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.emoji_events, color: Color(0xFFD32F2F)),
                    title: const Text('Nuevo Resultado'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResultadoFormScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.payment, color: Color(0xFFD32F2F)),
                    title: const Text('Nuevo Pago'),
                    onTap: () {
                      Navigator.pop(context);
                      // Navega a la pantalla de nuevo pago
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category, color: Color(0xFFD32F2F)),
                    title: const Text('Nueva Categoría-Equipo'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoriaEquipoFormScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar',
      ),
    );
  }
}
