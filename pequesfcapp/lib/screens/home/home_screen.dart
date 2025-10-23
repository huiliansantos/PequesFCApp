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
import '../asistencias/reporte_asistencia_screen.dart';
import '../profesor/profesor_list_screen.dart';
import '../asistencias/categoria_list_asistencia_screen.dart';
import '../categorias/categoria_equipo_form_screen.dart';
import '../profesor/profesor_form_screen.dart';
import '../reportes/reportes_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../categorias/categoria_list_screen.dart';
import '../torneos/torneo_list_screen.dart';
import '../torneos/torneo_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final String? jugadorId;
  final String? nombre;
  final String? apellido;

  const HomeScreen({
    super.key,
    required this.role,
    this.jugadorId,
    this.nombre,
    this.apellido,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<String> _adminTitles = [
    'Bienvenid@',
    'Jugadores',
    'Apoderados',
    'Partidos',
    'Resultados',
    'Pagos',
    'Asistencias',
    'Categorías-Equipos',
    'Profesores',
    'Torneos',
    'Reportes',
  ];

  static final List<Widget> _adminScreens = [
    AdminDashboardScreen(),
    PlayerListScreen(),
    GuardianListScreen(),
    MatchScheduleScreen(),
    ResultadosListScreen(),
    PaymentManagementScreen(),
    CategoriaListAsistenciaScreen(),
    CategoriaListScreen(), // <-- Aquí va la lista de categorías-equipos
    ProfesorListScreen(),
    TorneoListScreen(),
    ReportesScreen(),
  ];

  static const List<String> _apoderadoTitles = [
    'Jugadores',
    'Apoderados',
    'Partidos',
    'Resultados',
    'Pagos',
    'Asistencias',
    'Reportes',
  ];

  List<Widget> get _apoderadoScreens => [
        PlayerListScreen(),
        GuardianListScreen(),
        MatchScheduleScreen(),
        ResultadosListScreen(),
        PaymentManagementScreen(),
        ReporteAsistenciaScreen(jugadorId: widget.jugadorId ?? ''),
        ReportesScreen(),
      ];

  List<BottomNavigationBarItem> get _navItems => widget.role == 'admin'
      ? [
          const BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Jugadores'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom), label: 'Apoderados'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Partidos'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Resultados'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: 'Pagos'),
        ]
      : [
          const BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Jugadores'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Partidos'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Resultados'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: 'Pagos'),
        ];

  // Relaciona el índice del BottomNav con el índice de las pantallas principales
  List<int> get _bottomNavToScreenIndex =>
      widget.role == 'admin' ? [1, 2, 3, 4, 5] : [0, 2, 3, 4];

  List<Widget> _buildDrawerOptions(BuildContext context) {
    if (widget.role == 'admin') {
      return [
        _drawerItem(context, Icons.people, 'Inicio Administrador', 0),
        _drawerItem(context, Icons.people, 'Jugadores', 1),
        _drawerItem(context, Icons.family_restroom, 'Apoderados', 2),
        _drawerItem(context, Icons.sports_soccer, 'Partidos', 3),
        _drawerItem(context, Icons.emoji_events, 'Resultados', 4),
        _drawerItem(context, Icons.payment, 'Pagos', 5),
        _drawerItem(context, Icons.checklist, 'Asistencias', 6),
        _drawerItem(context, Icons.category, 'Categorías-Equipos', 7),
        _drawerItem(context, Icons.school, 'Profesores', 8),
        _drawerItem(context, Icons.emoji_events_outlined, 'Torneos', 9),
        _drawerItem(context, Icons.picture_as_pdf, 'Reportes', 10),
      ];
    } else {
      return [
        _drawerItem(context, Icons.people, 'Inicio Apoderado', 0),
        _drawerItem(context, Icons.people, 'Jugadores', 1),
        _drawerItem(context, Icons.family_restroom, 'Apoderados', 2),
        _drawerItem(context, Icons.sports_soccer, 'Partidos', 3),
        _drawerItem(context, Icons.emoji_events, 'Resultados', 4),
        _drawerItem(context, Icons.payment, 'Pagos', 5),
        _drawerItem(context, Icons.checklist, 'Asistencias', 6),
        _drawerItem(context, Icons.picture_as_pdf, 'Reportes', 7),
      ];
    }
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon,
          color: _selectedIndex == index ? const Color(0xFFD32F2F) : Colors.grey),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        Navigator.pop(context);
        if (title == 'Reportes') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportesScreen()),
          );
        } else if (title == 'Categorías-Equipos') {
          setState(() {
            _selectedIndex = 7; // Cambia el índice al de CategoriaListScreen
          });
        }else if (title == 'Torneos') {
          setState(() {
            _selectedIndex = 9; // Cambia el índice al de TorneoListScreen
          });
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens =
        widget.role == 'apoderado' ? _apoderadoScreens : _adminScreens;
    final titles = widget.role == 'apoderado' ? _apoderadoTitles : _adminTitles;

    // Calcula el índice seguro para el BottomNav
    int bottomNavIndex =
        _bottomNavToScreenIndex.indexWhere((i) => i == _selectedIndex);
    if (bottomNavIndex == -1) bottomNavIndex = 0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD32F2F),
                Color(0xFFF57C00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              titles[_selectedIndex],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Botón Home (solo para admin)
              if (widget.role == 'admin')
                IconButton(
                  icon: const Icon(Icons.home),
                  tooltip: 'Inicio administrador',
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // Ir al dashboard
                    });
                  },
                ),
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
        ),
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFD32F2F),
                      Color(0xFFF57C00),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: DrawerHeader(
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Escudo de la escuela
                        Image.asset(
                          'assets/peques.png',
                          width: 70,
                          height: 70,
                        ),
                        const SizedBox(height: 12),
                        // Nombre completo
                        Text(
                          '${widget.nombre ?? 'Usuario'} ${widget.apellido ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Rol
                        Text(
                          widget.role == 'admin' ? 'Administrador' : widget.role,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ..._buildDrawerOptions(context),
            ],
          ),
        ),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD32F2F),
              Color(0xFFF57C00),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: bottomNavIndex,
          onTap: (navIndex) {
            setState(() {
              _selectedIndex = _bottomNavToScreenIndex[navIndex];
            });
          },
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          items: _navItems,
        ),
      ),
      floatingActionButton: widget.role == 'admin'
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFF57C00),
              foregroundColor: Colors.white,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_add,
                              color: Color(0xFFD32F2F)),
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
                          leading: const Icon(Icons.family_restroom,
                              color: Color(0xFFD32F2F)),
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
                          leading: const Icon(Icons.sports_soccer,
                              color: Color(0xFFD32F2F)),
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
                          leading: const Icon(Icons.emoji_events,
                              color: Color(0xFFD32F2F)),
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
                          leading: const Icon(Icons.payment,
                              color: Color(0xFFD32F2F)),
                          title: const Text('Nuevo Pago'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentManagementScreen(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.category,
                              color: Color(0xFFD32F2F)),
                          title: const Text('Nueva Categoría-Equipo'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CategoriaEquipoFormScreen(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.school,
                              color: Color(0xFFD32F2F)),
                          title: const Text('Nuevo Profesor'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfesorFormScreen(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.emoji_events_outlined,
                              color: Color(0xFFD32F2F)),
                          title: const Text('Nuevo Torneo'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TorneoFormScreen(),
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
            )
          : null,
    );
  }
}
