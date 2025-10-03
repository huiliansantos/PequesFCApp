import 'package:flutter/material.dart';
import '../../models/profesor_model.dart';
import '../profesor/jugadores_profesor_screen.dart';
import '../profesor/partidos_profesor_screen.dart';
import '../profesor/resultados_profesor_screen.dart';
import '../profesor/asistencia_profesor_screen.dart';
import '../profesor/pagos_profesor_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login/login_screen.dart';

class ProfesorHomeScreen extends StatefulWidget {
  final ProfesorModel profesor;

  const ProfesorHomeScreen({Key? key, required this.profesor}) : super(key: key);

  @override
  State<ProfesorHomeScreen> createState() => _ProfesorHomeScreenState();
}

class _ProfesorHomeScreenState extends State<ProfesorHomeScreen> {
  int _selectedIndex = 0;

  static const List<String> _titles = [
    'Jugadores',
    'Partidos',
    'Resultados',
    'Asistencia',
    'Pagos',
  ];

  List<Widget> get _screens => [
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
      _drawerItem(context, Icons.people, 'Jugadores', 0),
      _drawerItem(context, Icons.sports_soccer, 'Partidos', 1),
      _drawerItem(context, Icons.emoji_events, 'Resultados', 2),
      _drawerItem(context, Icons.checklist, 'Asistencia', 3),
      _drawerItem(context, Icons.payments, 'Pagos', 4),
    ];
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? const Color(0xFFD32F2F) : Colors.grey),
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
              ..._buildDrawerOptions(context),
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
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Jugadores'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Partidos'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Resultados'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Asistencia'),
            BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Pagos'),
          ],
        ),
      ),
    );
  }
}