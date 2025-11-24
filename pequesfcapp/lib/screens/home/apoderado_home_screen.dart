import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/guardian_model.dart';
import '../../models/player_model.dart';
import '../../widgets/apoderado_drawer.dart';
import '../../services/auth_service.dart';
import '../asistencias/asistencia_hijo_screen.dart';
import '../payments/pagos_hijo_screen.dart';
import '../matches/partidos_hijo_screen.dart';
import '../resultados/resultados_hijo_screen.dart';
import '../login/login_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';

class ApoderadoHomeScreen extends StatefulWidget {
  final Map<String, dynamic> guardian;
  final List<dynamic> hijos;

  const ApoderadoHomeScreen({
    Key? key,
    required this.guardian,
    required this.hijos,
  }) : super(key: key);

  @override
  State<ApoderadoHomeScreen> createState() => _ApoderadoHomeScreenState();
}

class _ApoderadoHomeScreenState extends State<ApoderadoHomeScreen> {
  int _selectedIndex = 0;
  late GuardianModel guardianModel;
  late List<PlayerModel> hijosModel;

  @override
  void initState() {
    super.initState();
    guardianModel = GuardianModel.fromMap(widget.guardian);
    hijosModel = (widget.hijos as List<dynamic>)
        .map((h) => h is PlayerModel
            ? h
            : PlayerModel.fromMap(h as Map<String, dynamic>))
        .toList();
    debugPrint('✅ ApoderadoHomeScreen inicializado: ${guardianModel.nombreCompleto}');
  }

  static const List<String> _titles = [
    'Inicio',
    'Asistencia',
    'Pagos',
    'Partidos',
    'Resultados',
  ];

  List<Widget> get _screens => [
    AdminDashboardScreen(),
    AsistenciaHijoScreen(hijos: hijosModel),
    PagosHijoScreen(hijos: hijosModel),
    PartidosHijoScreen(hijos: hijosModel),
    ResultadosHijoScreen(hijos: hijosModel),
  ];

  Widget _drawerItem(
      BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? const Color(0xFFD32F2F) : Colors.grey,
      ),
      title: Text(title),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.red.shade50,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  // ✅ PANTALLA DE HIJOS
  Widget _buildHijosScreen() {
    return hijosModel.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes hijos registrados',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hijosModel.length,
            itemBuilder: (context, index) {
              final hijo = hijosModel[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFD32F2F),
                    child: Text(
                      hijo.iniciales,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    hijo.nombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Edad: ${hijo.edad} años • Grado: ${hijo.grado}',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    debugPrint('👀 Ver detalles de: ${hijo.nombreCompleto}');
                    // TODO: Navegar a pantalla de detalles del hijo
                  },
                ),
              );
            },
          );
  }

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
        debugPrint('🔐 Iniciando cierre de sesión...');

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
          .collection('guardianes')
          .doc(guardianModel.id)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        // ✅ ACTUALIZAR DATOS DEL APODERADO
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            guardianModel =
                GuardianModel.fromMap(data..['id'] = guardianModel.id);
            debugPrint('✅ Datos del apoderado actualizados');
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
          drawer: ApoderadoDrawer(
            guardian: guardianModel,
            onMenuItemSelected: (index) {
              setState(() => _selectedIndex = index);
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
                  icon: Icon(Icons.checklist),
                  label: 'Asistencia',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payment),
                  label: 'Pagos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_soccer),
                  label: 'Partidos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events),
                  label: 'Resultados',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}