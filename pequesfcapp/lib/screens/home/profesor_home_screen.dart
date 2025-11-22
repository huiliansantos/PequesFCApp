import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/profesor_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/profesor_drawer.dart';  // ✅ AGREGADO: Import ProfesorDrawer
import '../profesor/jugadores_profesor_screen.dart';
import '../profesor/partidos_profesor_screen.dart';
import '../profesor/resultados_profesor_screen.dart';
import '../profesor/asistencia_profesor_screen.dart';
import '../profesor/pagos_profesor_screen.dart';
import '../login/login_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../auth/change_password_manual_screen.dart';

class ProfesorHomeScreen extends StatefulWidget {
  final Map<String, dynamic> profesor;

  const ProfesorHomeScreen({Key? key, required this.profesor})
      : super(key: key);

  @override
  State<ProfesorHomeScreen> createState() => _ProfesorHomeScreenState();
}

class _ProfesorHomeScreenState extends State<ProfesorHomeScreen> {
  int _selectedIndex = 0;
  late ProfesorModel profesorModel;

  @override
  void initState() {
    super.initState();
    profesorModel = ProfesorModel.fromMap(widget.profesor);
    debugPrint('✅ ProfesorHomeScreen inicializado: ${profesorModel.nombre}');
  }

  List<String> get _titles => [
    'Bienvenido ${profesorModel.nombre}',
    'Jugadores',
    'Partidos',
    'Resultados',
    'Asistencia',
    'Pagos',
  ];

  List<Widget> get _screens => [
    AdminDashboardScreen(),
    JugadoresProfesorScreen(
      categoriaEquipoIdProfesor: profesorModel.categoriaEquipoId,
    ),
    PartidosProfesorScreen(
      categoriaEquipoIdProfesor: profesorModel.categoriaEquipoId,
    ),
    ResultadosProfesorScreen(
      categoriaEquipoIdProfesor: profesorModel.categoriaEquipoId,
    ),
    AsistenciaProfesorScreen(
      categoriaEquipoIdProfesor: profesorModel.categoriaEquipoId,
    ),
    PagosProfesorScreen(
      categoriaEquipoIdProfesor: profesorModel.categoriaEquipoId,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ StreamBuilder para escuchar cambios en tiempo real
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('profesores')
          .doc(profesorModel.id)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        // Actualizar datos si hay cambios
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            profesorModel = ProfesorModel.fromMap(data..['id'] = profesorModel.id);
          }
        }

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
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('¿Cerrar sesión?'),
                          content: const Text(
                              '¿Estás seguro de que deseas cerrar sesión?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Cerrar sesión'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await AuthService.cerrarSesion();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          // ✅ CAMBIO: Pasar onMenuItemSelected callback
          drawer: ProfesorDrawer(
            profesor: profesorModel,
            onMenuItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
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
                BottomNavigationBarItem(
                    icon: Icon(Icons.home), label: 'Inicio'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.people), label: 'Jugadores'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.sports_soccer), label: 'Partidos'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events), label: 'Resultados'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.checklist), label: 'Asistencia'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.payments), label: 'Pagos'),
              ],
            ),
          ),
        );
      },
    );
  }
}
