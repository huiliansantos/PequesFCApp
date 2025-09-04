import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class ResultadosHijoScreen extends StatelessWidget {
  final List<PlayerModel> hijos;

  const ResultadosHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.list),
          label: const Text('Ver todos los resultados'),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
          onPressed: () {
            // Navega a la pantalla de todos los resultados
            // Navigator.push(context, MaterialPageRoute(builder: (_) => TodosResultadosScreen()));
          },
        ),
        Expanded(
          child: ListView.builder(
            itemCount: hijos.length,
            itemBuilder: (context, index) {
              final hijo = hijos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Color(0xFFD32F2F)),
                  title: Text('${hijo.nombres} ${hijo.apellido}'),
                  subtitle: Text('CI: ${hijo.ci}'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
                    child: const Text('Ver resultados'),
                    onPressed: () {
                      // Navega a los resultados del hijo
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => ResultadosJugadorScreen(jugadorId: hijo.id)));
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}