import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../providers/guardian_provider.dart';
import '../guardians/guardian_detail_screen.dart';
import '../guardians/guardian_form_screen.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/categoria_equipo_provider.dart';

String calcularCategoria(DateTime fechaNacimiento) {
  final ahora = DateTime.now();
  int edad = ahora.year - fechaNacimiento.year;
  if (ahora.month < fechaNacimiento.month ||
      (ahora.month == fechaNacimiento.month && ahora.day < fechaNacimiento.day)) {
    edad--;
  }
  return 'Sub-$edad';
}

// La lógica de categoriaEquipo se mueve dentro del widget donde 'player' está disponible.

class PlayerDetailScreen extends ConsumerWidget {
  final PlayerModel player;

  const PlayerDetailScreen({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianAsync = player.guardianId != null
        ? ref.watch(guardianByIdProvider(player.guardianId!))
        : null;

    // Obtén el objeto CategoriaEquipoModel usando el provider
    final categoriaEquipoAsync = ref.watch(categoriasEquiposProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.nombres} ${player.apellido}'),
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/jugador.png'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailItem('Nombres', player.nombres, Icons.person),
                    _buildDetailItem(
                        'Apellido', player.apellido, Icons.person_outline),
                    _buildDetailItem(
                      'Fecha de Nacimiento',
                      '${player.fechaDeNacimiento.day}/${player.fechaDeNacimiento.month}/${player.fechaDeNacimiento.year}',
                      Icons.cake,
                    ),
                    _buildDetailItem(
                      'Departamento',
                      player.departamentoBolivia ?? 'Sin asignar',
                      Icons.location_city,
                    ),
                    _buildDetailItem('Género', player.genero, Icons.wc),
                    _buildDetailItem('CI', player.ci, Icons.badge),
                    _buildDetailItem(
                        'Nacionalidad', player.nacionalidad, Icons.flag),
                    _buildDetailItem('Categoría', calcularCategoria(player.fechaDeNacimiento), Icons.sports_soccer),
                    //mostrar el nombre del equipo que corresponde a ese ID
                    categoriaEquipoAsync.when(
                      loading: () => _buildDetailItem('Equipo', 'Cargando...', Icons.sports_soccer),
                      error: (e, _) => _buildDetailItem('Equipo', 'Error', Icons.sports_soccer),
                      data: (lista) {
                        final categoriaEquipo = lista.firstWhere(
                          (item) => item.id == player.categoriaEquipoId,
                          orElse: () => CategoriaEquipoModel(id: '', categoria: 'Sin asignar', equipo: ''),
                        );
                        return _buildDetailItem(
                          'Equipo',
                          '${categoriaEquipo.categoria} - ${categoriaEquipo.equipo}',
                          Icons.sports_soccer,
                        );
                      },
                    ),
                    _buildDetailItem(
                      'Estado de Pago',
                      player.estadoPago ?? 'Sin registro',
                      Icons.attach_money,
                      valueColor: player.estadoPago == 'Pagado'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Detalles del Apoderado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black12,
                    offset: Offset(1, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (player.guardianId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuardianDetailScreen(guardianId: player.guardianId!),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuardianFormScreen(jugador: player), // <-- Aquí pasas el jugador
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: guardianAsync == null
                      ? const ListTile(
                          leading: Icon(Icons.person_search),
                          title: Text('Apoderado'),
                          subtitle: Text('Sin asignar'),
                        )
                      : guardianAsync.when(
                          loading: () => const ListTile(
                            leading: Icon(Icons.person_search),
                            title: Text('Apoderado'),
                            subtitle: Text('Cargando...'),
                          ),
                          error: (e, _) => ListTile(
                            leading: const Icon(Icons.error, color: Colors.red),
                            title: const Text('Apoderado'),
                            subtitle: Text('Error: $e'),
                          ),
                          data: (guardian) => guardian == null
                              ? const ListTile(
                                  leading: Icon(Icons.person_search),
                                  title: Text('Apoderado'),
                                  subtitle: Text('Sin asignar'),
                                )
                              : Column(
                                  children: [
                                    _buildDetailItem('Nombre',
                                        guardian.nombreCompleto, Icons.person),
                                    _buildDetailItem(
                                        'CI', guardian.ci, Icons.badge),
                                    _buildDetailItem(
                                        'Celular', guardian.celular, Icons.phone),
                                  ],
                                ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                // Aquí puedes navegar a una pantalla para asignar o cambiar apoderado
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuardianFormScreen(jugador: player), // <-- Aquí pasas el jugador
                  ),
                );
                // Navigator.push(context, MaterialPageRoute(builder: (_) => AsignarApoderadoScreen(player: player)));
              },
              label: const Text('Asignar o Cambiar Apoderado'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD32F2F)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
