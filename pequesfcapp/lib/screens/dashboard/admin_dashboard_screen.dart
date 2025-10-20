import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 18),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamInfoAsync = ref.watch(teamInfoProvider);
    final playersCountAsync = ref.watch(playersCountProvider);
    final coachesCountAsync = ref.watch(coachesCountProvider);
    final matchesCountAsync = ref.watch(matchesCountProvider);
    final resultsCountAsync = ref.watch(resultsCountProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top card: logo + name + founding
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: teamInfoAsync.when(
                loading: () => const SizedBox(
                    height: 96,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Peques F.C.',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Fundación: Marzo 2014',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
                data: (info) {
                  final logo = info['logoUrl']?.toString() ?? '';
                  return Row(children: [
                    // logo: si tienes asset local usa Image.asset; si guardas URL, usa Image.network
                    if (logo.isNotEmpty)
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(logo,
                              width: 96, height: 96, fit: BoxFit.cover))
                    else
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/peques.png',
                              width: 96, height: 96)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(info['name'] ?? 'Peques F.C.',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                                'Fundación: ${info['founding'] ?? 'Marzo 2014'}',
                                style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 12),
                          ]),
                    )
                  ]);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info cards row (location + training + categories)
          teamInfoAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (info) {
              return Column(children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined,
                        color: Color(0xFFD32F2F)),
                    title: const Text('Lugar de entrenamiento',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(info['location'] ??
                        'Barrio SENAC \n Complejo Deportivo García Ágreda'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading:
                        const Icon(Icons.access_time, color: Color(0xFFF57C00)),
                    title: const Text('Entrenamientos',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        info['training'] ?? 'Lunes a viernes \n Mañana y tarde'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.groups, color: Color(0xFF7B1FA2)),
                    title: const Text('Categorías',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        info['categories'] ?? 'Niños de 3 años para adelante'),
                  ),
                ),
              ]);
            },
          ),

          const SizedBox(height: 16),

          // Stats grid
          Row(children: [
            Expanded(
              child: playersCountAsync.when(
                loading: () => _statCard(
                    'Jugadores', '...', Icons.sports_soccer, Colors.blue),
                error: (_, __) => _statCard(
                    'Jugadores', '0', Icons.sports_soccer, Colors.blue),
                data: (count) => _statCard('Jugadores', count.toString(),
                    Icons.sports_soccer, Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: coachesCountAsync.when(
                loading: () => _statCard(
                    'Profesores', '...', Icons.person, Colors.deepPurple),
                error: (_, __) => _statCard(
                    'Profesores', '0', Icons.person, Colors.deepPurple),
                data: (count) => _statCard('Profesores', count.toString(),
                    Icons.person, Colors.deepPurple),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: matchesCountAsync.when(
                loading: () => _statCard('Partidos programados', '...',
                    Icons.schedule, Colors.orange),
                error: (_, __) => _statCard(
                    'Partidos programados', '0', Icons.schedule, Colors.orange),
                data: (count) => _statCard('Partidos programados',
                    count.toString(), Icons.schedule, Colors.orange),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: resultsCountAsync.when(
                loading: () => _statCard(
                    'Resultados', '...', Icons.assessment, Colors.green),
                error: (_, __) => _statCard(
                    'Resultados', '0', Icons.assessment, Colors.green),
                data: (count) => _statCard('Resultados', count.toString(),
                    Icons.assessment, Colors.green),
              ),
            ),
          ]),

          const SizedBox(height: 18), // Acciones rápidas (botones)
        ]),
      ),
    );
  }
}
