import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../providers/guardian_provider.dart';
String calcularCategoria(DateTime fechaNacimiento) {
  final ahora = DateTime.now();
  int edad = ahora.year - fechaNacimiento.year;
  if (ahora.month < fechaNacimiento.month ||
      (ahora.month == fechaNacimiento.month && ahora.day < fechaNacimiento.day)) {
    edad--;
  }
  return 'Sub-$edad';
}
class PlayerDetailScreen extends ConsumerWidget {
  final PlayerModel player;

  const PlayerDetailScreen({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianAsync = player.guardianId != null
        ? ref.watch(guardianByIdProvider(player.guardianId!))
        : null;

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
                    // categoria se calcula de su fecha de nacimiento por ejemplo si nacio el 2016 es sub - 9
                    _buildDetailItem('Categoría', calcularCategoria(player.fechaDeNacimiento), Icons.sports_soccer),
                    //_buildDetailItem('Equipo', player.equipo!, Icons.sports_soccer),
                    _buildDetailItem(
                      'Estado de Pago',
                      player.estadoPago ?? 'Sin registro',
                      Icons.attach_money,
                      valueColor: player.estadoPago == 'Pagado'
                          ? Colors.green
                          : Colors.red,
                      //podemos aumentar categoria y equipo
                      // si tenemos la categoria y equipo en el modelo PlayerModel
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Subtítulo para apoderado
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
                // haciendo click que vaya al editar apoderado
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
