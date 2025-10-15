import 'package:flutter/material.dart';
import 'generar_reporte_screen.dart';
import 'seleccionar_categoria_screen.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportes = [
      {'titulo': 'Jugadores', 'tipo': 'jugadores'},
      {'titulo': 'Profesores', 'tipo': 'profesores'},
      {'titulo': 'Apoderados', 'tipo': 'apoderados'},
      {'titulo': 'Asistencias', 'tipo': 'asistencias'},
      {'titulo': 'Pagos', 'tipo': 'pagos'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes PDF')),
      body: ListView(
        children: reportes.map((reporte) => ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: Text(reporte['titulo']!),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FiltroReporteScreen(tipoReporte: reporte['tipo']!),
              ),
            );
          },
        )).toList(),
      ),
    );
  }
}

class FiltroReporteScreen extends StatelessWidget {
  final String tipoReporte;
  const FiltroReporteScreen({Key? key, required this.tipoReporte}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filtros = [];
    if (tipoReporte == 'jugadores') {
      filtros = [
        {'titulo': 'Todos', 'filtro': 'todos'},
        {'titulo': 'Por Categorías', 'filtro': 'por_categoria'},
        {'titulo': 'Por Categorías-Equipos', 'filtro': 'por_categoria_equipo'},
      ];
    } else if (tipoReporte == 'asistencias') {
      filtros = [
        {'titulo': 'Por Equipo', 'filtro': 'por_equipo'},
        {'titulo': 'Por Jugador', 'filtro': 'por_jugador'},
      ];
    } else if (tipoReporte == 'pagos') {
      filtros = [
        {'titulo': 'Por Estado', 'filtro': 'por_estado'},
        {'titulo': 'Por Jugador', 'filtro': 'por_jugador'},
      ];
    } else {
      filtros = [
        {'titulo': 'Todos', 'filtro': 'todos'},
      ];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Filtrar Reporte')),
      body: ListView(
        children: filtros.map((f) => ListTile(
          leading: const Icon(Icons.filter_alt),
          title: Text(f['titulo']!),
          trailing: const Icon(Icons.picture_as_pdf),
          onTap: () {
            if (tipoReporte == 'jugadores' && f['filtro'] == 'por_categoria') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SeleccionarCategoriaScreen(
                    tipoReporte: 'jugadores',
                    filtro: 'por_categoria',
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenerarReporteScreen(
                    tipoReporte: tipoReporte,
                    filtro: f['filtro']!,
                  ),
                ),
              );
            }
          },
        )).toList(),
      ),
    );
  }
}