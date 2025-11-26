import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/profesor_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/profesor_drawer.dart';
import '../profesor/jugadores_profesor_screen.dart';
import '../profesor/partidos_profesor_screen.dart';
import '../profesor/resultados_profesor_screen.dart';
import '../profesor/asistencia_profesor_screen.dart';
import '../profesor/pagos_profesor_screen.dart';
import '../login/login_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../results/resultado_form_screen.dart';

class ProfesorHomeScreen extends StatefulWidget {
  final Map<String, dynamic> profesor;

  const ProfesorHomeScreen({
    Key? key,
    required this.profesor,
  }) : super(key: key);

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

  // ✅ CERRAR SESIÓN CON CONFIRMACIÓN
  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        debugPrint('🔐 Iniciando cierre de sesión del profesor...');

        // ✅ 1. LIMPIAR SESIÓN LOCAL
        await AuthService.cerrarSesion();
        debugPrint('✅ Sesión local cerrada');

        // ✅ 2. CERRAR SESIÓN EN FIREBASE SI EXISTE
        try {
          await FirebaseAuth.instance.signOut();
          debugPrint('✅ Sesión Firebase cerrada');
        } catch (e) {
          debugPrint('⚠️ Error cerrando sesión Firebase: $e');
        }

        if (context.mounted) {
          // ✅ 3. NAVEGAR A LOGIN
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
          debugPrint('✅ Navegado a LoginScreen');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
          debugPrint('❌ Error al cerrar sesión: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ STREAM PARA ACTUALIZAR DATOS EN TIEMPO REAL
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('profesores')
          .doc(profesorModel.id)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        // ✅ ACTUALIZAR DATOS DEL PROFESOR
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            profesorModel = ProfesorModel.fromMap(data
              ..['id'] = profesorModel.id);
            debugPrint('✅ Datos del profesor actualizados');
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  // ✅ BOTÓN INICIO
                  IconButton(
                    icon: const Icon(Icons.home),
                    tooltip: 'Ir a inicio',
                    onPressed: () {
                      setState(() => _selectedIndex = 0);
                    },
                  ),
                  // ✅ BOTÓN CERRAR SESIÓN
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Cerrar sesión',
                    onPressed: _cerrarSesion,
                  ),
                ],
              ),
            ),
          ),

          // ✅ DRAWER CON NAVEGACIÓN
          drawer: ProfesorDrawer(
            profesor: profesorModel,
            onMenuItemSelected: (index) {
              setState(() => _selectedIndex = index);
              Navigator.pop(context);
            },
          ),

          // ✅ BODY CON PANTALLAS
          body: _screens[_selectedIndex],

          // ✅ BOTTOM NAVIGATION BAR
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
              onTap: (index) {
                setState(() => _selectedIndex = index);
              },
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Jugadores',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_soccer),
                  label: 'Partidos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events),
                  label: 'Resultados',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.checklist),
                  label: 'Asistencia',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payments),
                  label: 'Pagos',
                ),
              ],
            ),
          ),

          // ✅ FAB para registrar nuevo resultado
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFF57C00),
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultadoFormScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
            tooltip: 'Registrar resultado',
          ),
        );
      },
    );
  }
}
