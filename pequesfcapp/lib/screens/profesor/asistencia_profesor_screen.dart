import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/asistencia_provider.dart';
import '../asistencias/registro_asistencia_screen.dart';
import '../asistencias/ver_lista_asistencia_screen.dart';

class AsistenciaProfesorScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoIdProfesor;

  const AsistenciaProfesorScreen({Key? key, required this.categoriaEquipoIdProfesor}) : super(key: key);

  @override
  ConsumerState<AsistenciaProfesorScreen> createState() => _AsistenciaProfesorScreenState();
}

class _AsistenciaProfesorScreenState extends ConsumerState<AsistenciaProfesorScreen> {
  late String filtro;

  @override
  void initState() {
    super.initState();
    filtro = widget.categoriaEquipoIdProfesor;
  }

  @override
  Widget build(BuildContext context) {
    final categoriasStream = FirebaseFirestore.instance.collection('categoria_equipo').snapshots();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: categoriasStream,
              builder: (context, snapshot) {
                final categorias = snapshot.hasData
                    ? snapshot.data!.docs
                        .map((d) => {
                              'id': d.id,
                              'categoria': d['categoria'],
                              'equipo': d['equipo'],
                            })
                        .where((cat) => cat['id'] == widget.categoriaEquipoIdProfesor)
                        .toList()
                    : [];
                return categorias.isEmpty
                    ? const Text('No tienes equipos asignados.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categorias.length,
                        itemBuilder: (context, index) {
                          final cat = categorias[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.red,
                                child: Icon(Icons.group, color: Colors.white),
                              ),
                              title: Text(
                                '${cat['categoria']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text('Equipo: ${cat['equipo']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.checklist, color: Colors.green),
                                    tooltip: 'Registrar asistencia',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RegistroAsistenciaScreen(
                                            categoriaEquipoId: cat['id'],
                                            entrenamientoId: 'entrenamientoId', // Pasa el ID real si lo tienes
                                            fecha: DateTime.now(),
                                            rol: 'profesor',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.list_alt, color: Colors.blue),
                                    tooltip: 'Ver historial',
                                    onPressed: () {
                                      // Aquí navega al historial de asistencias de ese equipo
                                      // Navigator.push(...);
                                      Navigator.push( 
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VerListaAsistenciaScreen(
                                            categoriaEquipoId: cat['id'],
                                          ),
                                        ),
                                      );
                                      
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
          // Puedes agregar aquí más widgets si necesitas
        ],
      ),
    );
  }
}