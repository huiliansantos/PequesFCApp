import 'package:flutter/material.dart';
import '../../models/profesor_model.dart';
import '../profesor/jugadores_profesor_screen.dart';
import '../profesor/partidos_profesor_screen.dart';
import '../profesor/resultados_profesor_screen.dart';
import '../profesor/asistencia_profesor_screen.dart';
import '../profesor/pagos_profesor_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login/login_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../auth/change_password_manual_screen.dart'; // <-- nuevo import (pantalla de cambio manual)

class ProfesorHomeScreen extends StatefulWidget {
  final ProfesorModel profesor;

  const ProfesorHomeScreen({Key? key, required this.profesor})
      : super(key: key);

  @override
  State<ProfesorHomeScreen> createState() => _ProfesorHomeScreenState();
}

class _ProfesorHomeScreenState extends State<ProfesorHomeScreen> {
  int _selectedIndex = 0;

  // CORRECCIÓN: falta una coma después de 'Inicio'
  List<String> get _titles => [
    //que diga bienvenido y el nombre del profesor.
    'Bienvenido ${widget.profesor.nombre}',
    'Jugadores',
    'Partidos',
    'Resultados',
    'Asistencia',
    'Pagos',
  ];

  // Añadimos una pantalla Inicio ligera para mantener la consistencia con el bottom nav
  List<Widget> get _screens => [
        AdminDashboardScreen(),
        JugadoresProfesorScreen(
          categoriaEquipoIdProfesor: widget.profesor.categoriaEquipoId,
        ),
        PartidosProfesorScreen(
          categoriaEquipoIdProfesor: widget.profesor.categoriaEquipoId,
        ),
        ResultadosProfesorScreen(
          categoriaEquipoIdProfesor: widget.profesor.categoriaEquipoId,
        ),
        AsistenciaProfesorScreen(
          categoriaEquipoIdProfesor: widget.profesor.categoriaEquipoId,
        ),
        PagosProfesorScreen(
          categoriaEquipoIdProfesor: widget.profesor.categoriaEquipoId,
        ),
      ];

  List<Widget> _buildDrawerOptions(BuildContext context) {
    return [
      _drawerItem(context, Icons.home, 'Inicio', 0),
      _drawerItem(context, Icons.people, 'Jugadores', 1),
      _drawerItem(context, Icons.sports_soccer, 'Partidos', 2),
      _drawerItem(context, Icons.emoji_events, 'Resultados', 3),
      _drawerItem(context, Icons.checklist, 'Asistencia', 4),
      _drawerItem(context, Icons.payments, 'Pagos', 5),
    ];
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
              _titles[_selectedIndex],
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
                        Image.asset(
                          'assets/peques.png',
                          width: 70,
                          height: 70,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${widget.profesor.nombre} ${widget.profesor.apellido}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Profesor',
                          style: TextStyle(
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

              // Opciones principales del menú
              ..._buildDrawerOptions(context),

              const Divider(),
              // Usuario y ver contraseña colocados al final, separados por un Divider
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Usuario'),
                subtitle: Text(widget.profesor.usuario.isNotEmpty
                    ? widget.profesor.usuario
                    : '---'),
                onTap: () {
                  // opcional: navegar a perfil / editar
                },
              ),

              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Ver contraseña'),
                subtitle: Text(widget.profesor.contrasena.isNotEmpty
                    ? 'Mostrar / Ocultar'
                    : 'No disponible'),
                onTap: () {
                  if (widget.profesor.contrasena.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Contraseña'),
                        content: const Text(
                            'La contraseña no está disponible. Puedes cambiarla de forma segura.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ChangePasswordManualScreen(
                                              profesor: widget.profesor)));
                            },
                            child: const Text('Cambiar contraseña'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  bool obscure = true;
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return StatefulBuilder(builder: (ctx2, setState) {
                        return AlertDialog(
                          title: const Text('Contraseña'),
                          content: Row(
                            children: [
                              Expanded(
                                  child: Text(obscure
                                      ? '●●●●●●●'
                                      : widget.profesor.contrasena)),
                              IconButton(
                                  icon: Icon(obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () =>
                                      setState(() => obscure = !obscure)),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cerrar')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ChangePasswordManualScreen(
                                                profesor: widget.profesor)));
                              },
                              child: const Text('Cambiar contraseña'),
                            ),
                          ],
                        );
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _screens[_selectedIndex],
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
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people), label: 'Jugadores'),
            BottomNavigationBarItem(
                icon: Icon(Icons.sports_soccer), label: 'Partidos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events), label: 'Resultados'),
            BottomNavigationBarItem(
                icon: Icon(Icons.checklist), label: 'Asistencia'),
            BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Pagos'),
          ],
        ),
      ),
    );
  }
}
