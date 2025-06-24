import 'package:flutter/material.dart';

// Simulación de datos de resultados
final List<Map<String, dynamic>> resultados = [
  {
    'rival': 'Tiburones FC',
    'categoria': 'Sub-10',
    'fecha': DateTime(2024, 6, 20, 10, 0),
    'lugar': 'Estadio Central',
    'resultado': '3 - 1',
    'observaciones': 'Buen partido, gran defensa.',
  },
  {
    'rival': 'Leones FC',
    'categoria': 'Sub-8',
    'fecha': DateTime(2024, 6, 22, 9, 30),
    'lugar': 'Cancha Norte',
    'resultado': '2 - 2',
    'observaciones': 'Empate luchado.',
  },
  {
    'rival': 'Águilas FC',
    'categoria': 'Sub-10',
    'fecha': DateTime(2024, 6, 27, 11, 0),
    'lugar': 'Estadio Central',
    'resultado': '0 - 4',
    'observaciones': 'Faltó concentración.',
  },
];

class ResultRegistrationScreen extends StatefulWidget {
  const ResultRegistrationScreen({super.key});

  @override
  State<ResultRegistrationScreen> createState() => _ResultRegistrationScreenState();
}

class _ResultRegistrationScreenState extends State<ResultRegistrationScreen> {
  String? categoriaSeleccionada;

  @override
  Widget build(BuildContext context) {
    // Obtén las categorías únicas
    final categorias = resultados.map((r) => r['categoria'] as String).toSet().toList();

    // Filtra por categoría
    final resultadosFiltrados = resultados.where((resultado) {
      return categoriaSeleccionada == null || resultado['categoria'] == categoriaSeleccionada;
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
              const Icon(Icons.emoji_events, color: Color(0xFFD32F2F), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resultados de Partidos',
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
          child: resultadosFiltrados.isEmpty
              ? const Center(child: Text('No hay resultados para esta categoría.'))
              : ListView.builder(
                  itemCount: resultadosFiltrados.length,
                  itemBuilder: (context, index) {
                    final resultado = resultadosFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        //podemos cambiar el icono por el logo de los peques
                        leading: Image.asset(
                          'assets/peques.png',
                          width: 50,
                          height: 50,
                        ),
                        title: Text('${resultado['rival']} (${resultado['categoria']})'),
                        subtitle: Text(
                          'Fecha: ${resultado['fecha'].day}/${resultado['fecha'].month}/${resultado['fecha'].year} '
                          'Hora: ${resultado['fecha'].hour.toString().padLeft(2, '0')}:${resultado['fecha'].minute.toString().padLeft(2, '0')}\n'
                          'Lugar: ${resultado['lugar']}\n'
                          'Resultado: ${resultado['resultado']}\n'
                          'Observaciones: ${resultado['observaciones']}',
                        ),
                        onTap: () {
                          // Acción para ver detalle o editar resultado
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
                // Acción para registrar nuevo resultado
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}