import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../providers/guardian_provider.dart';
import '../guardians/guardian_detail_screen.dart';
import '../../models/categoria_equipo_model.dart';
import '../guardians/asignar_apoderado_screen.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../providers/pago_provider.dart';

String calcularCategoria(DateTime fechaNacimiento) {
  final ahora = DateTime.now();
  int edad = ahora.year - fechaNacimiento.year;
  if (ahora.month < fechaNacimiento.month ||
      (ahora.month == fechaNacimiento.month &&
          ahora.day < fechaNacimiento.day)) {
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
    final categoriaEquipoAsync = ref.watch(categoriasEquiposProvider);

    // Obtén los pagos del jugador
    final pagosAsync = ref.watch(pagosPorJugadorProvider(player.id));
    final gestionActual = DateTime.now().year;
    const mesesDelAno = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.nombres} ${player.apellido}'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
                    _buildDetailItem('Nombres', player.nombres, Icons.person, iconColor: Colors.blue),
                    _buildDetailItem('Apellido', player.apellido, Icons.person_outline, iconColor: Colors.blue),
                    _buildDetailItem(
                      'Fecha de Nacimiento',
                      '${player.fechaDeNacimiento.day}/${player.fechaDeNacimiento.month}/${player.fechaDeNacimiento.year}',
                      Icons.cake,
                      iconColor: Colors.purple
                    ),
                    _buildDetailItem(
                      'Departamento',
                      player.departamentoBolivia ?? 'Sin asignar',
                      Icons.location_city,
                      iconColor: Colors.orange
                    ),
                    _buildDetailItem('Género', player.genero, Icons.wc, iconColor: Colors.teal),
                    _buildDetailItem('CI', player.ci, Icons.badge, iconColor: Colors.blue),
                    _buildDetailItem(
                        'Nacionalidad', player.nacionalidad, Icons.flag, iconColor: Colors.red),
                    categoriaEquipoAsync.when(
                      loading: () => _buildDetailItem('Categoria - Equipo',
                          'Cargando...', Icons.sports_soccer, iconColor: Colors.green),
                      error: (e, _) => _buildDetailItem(
                          'Categoria - Equipo', 'Error', Icons.sports_soccer, iconColor: Colors.green),
                      data: (lista) {
                        final categoriaEquipo = lista.firstWhere(
                          (item) => item.id == player.categoriaEquipoId,
                          orElse: () => CategoriaEquipoModel(
                              id: '', categoria: 'Sin asignar', equipo: ''),
                        );
                        return _buildDetailItem(
                          'Cat - Equipo',
                          '${categoriaEquipo.categoria} - ${categoriaEquipo.equipo}',
                          Icons.sports_soccer,
                          iconColor: Colors.green,
                        );
                      },
                    ),
                    // Estado de Pago calculado desde la BD
                    pagosAsync.when(
                      loading: () => _buildDetailItem(
                        'Estado de Pago', 'Cargando...', Icons.attach_money),
                      error: (e, _) => _buildDetailItem(
                        'Estado de Pago', 'Error', Icons.attach_money),
                      data: (pagos) {
                        final pagosGestion = pagos.where((p) => p.anio == gestionActual).toList();
                        int ultimoMesPagado = -1;
                        for (var pago in pagosGestion) {
                          if (pago.estado == 'pagado') {
                            int mesIndex = mesesDelAno.indexOf(pago.mes);
                            if (mesIndex > ultimoMesPagado) {
                              ultimoMesPagado = mesIndex;
                            }
                          }
                        }
                        int mesActual = DateTime.now().month - 1;
                        int mesesDeuda = mesActual - ultimoMesPagado;

                        Color estadoColor;
                        String estadoTexto;

                        if (pagosGestion.isEmpty) {
                          estadoColor = Colors.grey;
                          estadoTexto = 'Sin registro';
                        } else if (ultimoMesPagado >= mesActual) {
                          estadoColor = Colors.green;
                          estadoTexto = 'Pagado';
                        } else if (mesesDeuda > 3) {
                          estadoColor = Colors.red;
                          estadoTexto = 'Atrasado';
                        } else {
                          estadoColor = Colors.orange;
                          estadoTexto = 'Pendiente';
                        }

                        return _buildDetailItem(
                          'Estado de Pago',
                          estadoTexto,
                          Icons.attach_money,
                          valueColor: estadoColor,
                        );
                      },
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
                        builder: (_) => GuardianDetailScreen(
                            guardianId: player.guardianId!),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AsignarApoderadoScreen(jugador: player),
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
                                    _buildDetailItem('Celular',
                                        guardian.celular, Icons.phone),
                                  ],
                                ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon,
      {Color? valueColor, Color iconColor = const Color(0xFFD32F2F)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Menor espacio
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.black, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
