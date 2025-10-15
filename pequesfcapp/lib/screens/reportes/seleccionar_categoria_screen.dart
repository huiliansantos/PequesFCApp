import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'generar_reporte_screen.dart';

class SeleccionarCategoriaScreen extends StatelessWidget {
  final String tipoReporte;
  final String filtro;

  const SeleccionarCategoriaScreen({Key? key, required this.tipoReporte, required this.filtro}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('categoria_equipo').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categorias = snapshot.data!.docs.map((doc) => doc['categoria'].toString()).toSet().toList();
        categorias.sort(); // Opcional: ordena las categorías
        return Scaffold(
          appBar: AppBar(title: const Text('Selecciona Categoría')),
          body: ListView(
            children: categorias.map((cat) => ListTile(
              title: Text(cat),
              trailing: const Icon(Icons.picture_as_pdf),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenerarReporteScreen(
                      tipoReporte: tipoReporte,
                      filtro: cat, // Aquí pasas la categoría seleccionada
                    ),
                  ),
                );
              },
            )).toList(),
          ),
        );
      },
    );
  }
}