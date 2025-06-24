import 'package:flutter/material.dart';

// Simulación de datos de partidos
final List<Map<String, dynamic>> partidos = [
  {
    'rival': 'Tiburones FC',
    'categoria': 'Sub-10',
    'fecha': DateTime(2024, 6, 20, 10, 0),
    'lugar': 'Estadio Central',
  },
  {
    'rival': 'Leones FC',
    'categoria': 'Sub-8',
    'fecha': DateTime(2024, 6, 22, 9, 30),
    'lugar': 'Cancha Norte',
  },
  {
    'rival': 'Águilas FC',
    'categoria': 'Sub-10',
    'fecha': DateTime(2024, 6, 27, 11, 0),
    'lugar': 'Estadio Central',
  },
];

class MatchScheduleScreen extends StatefulWidget {
  const MatchScheduleScreen({super.key});

  @override
  State<MatchScheduleScreen> createState() => _MatchScheduleScreenState();
}

class _MatchScheduleScreenState extends State<MatchScheduleScreen> {
  String? categoriaSeleccionada;

  @override
  Widget build(BuildContext context) {
    // Obtén las categorías únicas
    final categorias = partidos.map((p) => p['categoria'] as String).toSet().toList();

    // Filtra por categoría
    final partidosFiltrados = partidos.where((partido) {
      return categoriaSeleccionada == null || partido['categoria'] == categoriaSeleccionada;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<String>(
            value: categoriaSeleccionada,
            hint: const Text('Filtrar por categoría'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              ...categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
            ],
            onChanged: (value) {
              setState(() {
                categoriaSeleccionada = value;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFFD32F2F), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Calendario de Partidos',
                  style: const TextStyle(
                    fontSize: 22,
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: partidosFiltrados.isEmpty
              ? const Center(child: Text('No hay partidos para esta categoría.'))
              : ListView.builder(
                  itemCount: partidosFiltrados.length,
                  itemBuilder: (context, index) {
                    final partido = partidosFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        //podemos cambiar el icono por el logo de los peques
                        leading: Image.asset(
                          'assets/peques.png',
                          width: 50,
                          height: 50,
                        ),
                        title: Text('${partido['rival']} (${partido['categoria']})'),
                        subtitle: Text(
                          'Fecha: ${partido['fecha'].day}/${partido['fecha'].month}/${partido['fecha'].year} '
                          'Hora: ${partido['fecha'].hour.toString().padLeft(2, '0')}:${partido['fecha'].minute.toString().padLeft(2, '0')}\n'
                          'Lugar: ${partido['lugar']}',
                        ),
                        onTap: () {
                          // Acción para ver detalle del partido
                        },
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                // Acción para agregar un nuevo partido
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}