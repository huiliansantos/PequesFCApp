import 'package:flutter/material.dart';
import '../../models/match_model.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchModel match;

  const MatchDetailScreen({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Partido'),
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 2,
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
                ListTile(
                  leading: const Icon(Icons.category, color: Colors.purple),
                  title: const Text('Categoría'),
                  subtitle: Text(match.categoria),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}