import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class AsistenciaHijoScreen extends StatelessWidget {
  final List<PlayerModel> hijos;

  const AsistenciaHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: hijos.length,
      itemBuilder: (context, index) {
        final hijo = hijos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.person, color: Color(0xFFD32F2F)),
            title: Text('${hijo.nombres} ${hijo.apellido}'),
            subtitle: Text('CI: ${hijo.ci}'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
              child: const Text('Ver asistencia'),
              onPressed: () {
                // Navega a la pantalla de asistencia detallada del hijo
                // Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleAsistenciaScreen(jugadorId: hijo.id)));
              },
            ),
          ),
        );
      },
    );
  }
}