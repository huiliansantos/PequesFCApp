import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/match_model.dart';
import '../results/resultado_form_screen.dart';
import '../../widgets/gradient_button.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchModel match;

  const MatchDetailScreen({Key? key, required this.match}) : super(key: key);

  static final Future<Map<String, String>> _categoriaEquipoMapFuture =
      FirebaseFirestore.instance.collection('categoria_equipo').get().then((query) {
    final map = <String, String>{};
    for (final doc in query.docs) {
      final data = doc.data();
      final categoria = (data['categoria'] ?? '').toString();
      final equipo = (data['equipo'] ?? '').toString();
      final label = [
        if (categoria.isNotEmpty) categoria,
        if (equipo.isNotEmpty) equipo,
      ].join(' - ');
      map[doc.id] = label.isNotEmpty ? label : doc.id;
    }
    return map;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Partido'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/peques.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'vs ${match.equipoRival}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                FutureBuilder<Map<String, String>>(
                  future: _categoriaEquipoMapFuture,
                  builder: (context, snapshot) {
                    final idToLabel = snapshot.data ?? {};
                    final categoriaEquipoNombre = idToLabel[match.categoriaEquipoId] ?? match.categoriaEquipoId;
                    return ListTile(
                      leading: const Icon(Icons.category, color: Colors.purple),
                      title: const Text('Categoría'),
                      subtitle: Text(categoriaEquipoNombre),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text('Fecha'),
                  subtitle: Text('${match.fecha.day}/${match.fecha.month}/${match.fecha.year}'),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.teal),
                  title: const Text('Hora'),
                  subtitle: Text(match.hora),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.orange),
                  title: const Text('Cancha'),
                  subtitle: Text(match.cancha),
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.green),
                  title: const Text('Torneo'),
                  subtitle: Text(match.torneo),
                ),
                const SizedBox(height: 24),
                Center(
                  // en este boton que cuando haga click navegue al registrar resultado, 
                  child: GradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultadoFormScreen(
                            partidoId: match.id, // Solo envía el ID
                          ),
                        ),
                      );
                    },
                    child: const Text('Registrar Resultado'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}