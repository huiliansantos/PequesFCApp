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
import '../profesor/profesor_list_screen.dart';
import '../asistencias/categoria_list_asistencia_screen.dart';
import '../categorias/categoria_equipo_form_screen.dart';
import '../profesor/profesor_form_screen.dart';

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
    'Jugadores',
    'Apoderados',
    'Partidos',
    'Resultados',
    'Pagos',
    'Asistencias',
    'Categorías-Equipos',
    'Profesores',
    'Torneos',
  ];

  static final List<Widget> _adminScreens = [
    PlayerListScreen(),
    GuardianListScreen(),
    MatchScheduleScreen(),
    ResultadosListScreen(),
    PaymentManagementScreen(),
    CategoriaListAsistenciaScreen(),
    ReporteAsistenciaScreen(jugadorId: ''),
    ProfesorListScreen(),
    Center(child: Text('Torneos')), // Placeholder
  ];

  static const List<String> _apoderadoTitles = [
    'Jugadores',
    'Apoderados',
    'Partidos',
    'Resultados',
    'Pagos',
    'Asistencias',
  ];

  List<Widget> get _apoderadoScreens => [
        PlayerListScreen(),
        GuardianListScreen(),
        MatchScheduleScreen(),
        ResultadosListScreen(),
        PaymentManagementScreen(),
        ReporteAsistenciaScreen(jugadorId: widget.jugadorId ?? ''),
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
      widget.role == 'admin' ? [0, 1, 2, 3, 4] : [0, 2, 3, 4];

  List<Widget> _buildDrawerOptions(BuildContext context) {
    if (widget.role == 'admin') {
      return [
        _drawerItem(context, Icons.people, 'Jugadores', 0),
        _drawerItem(context, Icons.family_restroom, 'Apoderados', 1),
        _drawerItem(context, Icons.sports_soccer, 'Partidos', 2),
        _drawerItem(context, Icons.emoji_events, 'Resultados', 3),
        _drawerItem(context, Icons.payment, 'Pagos', 4),
        _drawerItem(context, Icons.category, 'Asistencias', 5),
        _drawerItem(context, Icons.checklist, 'Categorías-Equipos', 6),
        _drawerItem(context, Icons.school, 'Profesores', 7),
        _drawerItem(context, Icons.emoji_events_outlined, 'Torneos', 8),
      ];
    } else {
      return [
        _drawerItem(context, Icons.people, 'Jugadores', 0),
        _drawerItem(context, Icons.family_restroom, 'Apoderados', 1),
        _drawerItem(context, Icons.sports_soccer, 'Partidos', 2),
        _drawerItem(context, Icons.emoji_events, 'Resultados', 3),
        _drawerItem(context, Icons.payment, 'Pagos', 4),
        _drawerItem(context, Icons.checklist, 'Asistencias', 5),
      ];
    }
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon,
          color:
              _selectedIndex == index ? const Color(0xFFD32F2F) : Colors.grey),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
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
          gradient:  LinearGradient(
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
