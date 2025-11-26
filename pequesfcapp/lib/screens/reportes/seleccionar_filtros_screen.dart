import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reportes_pdf_preview_screen.dart';
import '../../widgets/gradient_button.dart';

class SeleccionarFiltrosScreen extends StatefulWidget {
  final String tipoReporte;

  const SeleccionarFiltrosScreen({
    Key? key,
    required this.tipoReporte,
  }) : super(key: key);

  @override
  State<SeleccionarFiltrosScreen> createState() => _SeleccionarFiltrosScreenState();
}

class _SeleccionarFiltrosScreenState extends State<SeleccionarFiltrosScreen> {
  String? categoriaSeleccionada;
  String? jugadorSeleccionado;
  DateTime? fechaInicio;
  DateTime? fechaFin;
  bool isLoading = true;
  bool isJugadoresLoading = false;
  List<DropdownMenuItem<String>> categorias = [];
  List<DropdownMenuItem<String>> jugadores = [];

  List<DropdownMenuItem<String>> profesores = [];
  List<DropdownMenuItem<String>> apoderados = [];
  String? profesorSeleccionado;
  String? apoderadoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarCategoriasYOtros();
  }

  Future<void> _cargarCategoriasYOtros() async {
    setState(() => isLoading = true);
    try {
      final categoriasSnapshot = await FirebaseFirestore.instance
          .collection('categoria_equipo')
          .get();

      categorias = categoriasSnapshot.docs.map((doc) {
        final data = doc.data();
        final categoria = data['categoria'] ?? '';
        final equipo = data['equipo'] ?? '';
        return DropdownMenuItem<String>(
          value: doc.id,
          child: Text('$categoria - $equipo'),
        );
      }).toList();

      categorias.sort((a, b) => (a.child as Text).data!.compareTo((b.child as Text).data!));

      // Profesores
      if (widget.tipoReporte == 'profesores') {
        final profesoresSnapshot = await FirebaseFirestore.instance
            .collection('profesores')
            .where('rol', isEqualTo: 'profesor')
            .orderBy('apellido')
            .get();

        profesores = profesoresSnapshot.docs.map((doc) {
          final data = doc.data();
          return DropdownMenuItem(
            value: doc.id,
            child: Text('${data['apellido'] ?? ''}, ${data['nombre'] ?? ''}'),
          );
        }).toList();
      }

      // Apoderados
      if (widget.tipoReporte == 'apoderados') {
        final apoderadosSnapshot = await FirebaseFirestore.instance
            .collection('guardianes')
            .where('rol', isEqualTo: 'apoderado')
            .orderBy('apellido')
            .get();

        apoderados = apoderadosSnapshot.docs.map((doc) {
          final data = doc.data();
          return DropdownMenuItem(
            value: doc.id,
            child: Text('${data['apellido'] ?? ''}, ${data['nombre'] ?? ''}'),
          );
        }).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _cargarJugadoresPorCategoria(String? categoriaId) async {
    setState(() {
      isJugadoresLoading = true;
      jugadorSeleccionado = null;
      jugadores = [];
    });

    try {
      QuerySnapshot<Map<String, dynamic>> jugadoresSnapshot;
      if (categoriaId == null) {
        jugadoresSnapshot = await FirebaseFirestore.instance
            .collection('jugadores')
            .orderBy('apellido')
            .get();
      } else {
        jugadoresSnapshot = await FirebaseFirestore.instance
            .collection('jugadores')
            .where('categoriaEquipoId', isEqualTo: categoriaId)
            .orderBy('apellido')
            .get();
      }

      jugadores = jugadoresSnapshot.docs.map((doc) {
        final data = doc.data();
        return DropdownMenuItem(
          value: doc.id,
          child: Text('${data['apellido'] ?? ''}, ${data['nombres'] ?? ''}'),
        );
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando jugadores: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isJugadoresLoading = false);
    }
  }

  Future<void> _cargarProfesoresPorCategoria(String? categoriaId) async {
    setState(() {
      profesores = [];
      profesorSeleccionado = null;
      isJugadoresLoading = true;
    });

    try {
      QuerySnapshot<Map<String, dynamic>> profesoresSnapshot;
      if (categoriaId == null) {
        profesoresSnapshot = await FirebaseFirestore.instance
            .collection('profesores')
            .where('rol', isEqualTo: 'profesor')
            .orderBy('apellido')
            .get();
      } else {
        profesoresSnapshot = await FirebaseFirestore.instance
            .collection('profesores')
            .where('rol', isEqualTo: 'profesor')
            .where('categoriaEquipoId', isEqualTo: categoriaId)
            .orderBy('apellido')
            .get();
      }

      profesores = profesoresSnapshot.docs.map((doc) {
        final data = doc.data();
        return DropdownMenuItem(
          value: doc.id,
          child: Text('${data['apellido'] ?? ''}, ${data['nombre'] ?? ''}'),
        );
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando profesores: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isJugadoresLoading = false);
    }
  }

  Widget _buildFiltros() {
    switch (widget.tipoReporte) {
      case 'jugadores':
      case 'jugadores_categoria':
      case 'jugadores_categoria_equipo':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar por categoría:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: categoriaSeleccionada,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
                ...categorias,
              ],
              onChanged: (value) {
                setState(() => categoriaSeleccionada = value);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        );

      case 'pagos_estado':
      case 'pagos_jugador':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar por:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: categoriaSeleccionada,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
                ...categorias,
              ],
              onChanged: (value) async {
                setState(() {
                  categoriaSeleccionada = value;
                  jugadorSeleccionado = null;
                  jugadores = [];
                });
                await _cargarJugadoresPorCategoria(value);
              },
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            isJugadoresLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: jugadorSeleccionado,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos los jugadores')),
                      ...jugadores,
                    ],
                    onChanged: (value) => setState(() => jugadorSeleccionado = value),
                    decoration: const InputDecoration(
                      labelText: 'Jugador',
                      border: OutlineInputBorder(),
                    ),
                  ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fecha inicio',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: fechaInicio?.toString().split(' ')[0] ?? '',
                    ),
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: fechaInicio ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (fecha != null && mounted) {
                        setState(() => fechaInicio = fecha);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fecha fin',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: fechaFin?.toString().split(' ')[0] ?? '',
                    ),
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: fechaFin ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (fecha != null && mounted) {
                        setState(() => fechaFin = fecha);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case 'profesores':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar profesores:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: categoriaSeleccionada,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
                ...categorias,
              ],
              onChanged: (value) async {
                setState(() {
                  categoriaSeleccionada = value;
                  profesorSeleccionado = null;
                  profesores = [];
                });
                await _cargarProfesoresPorCategoria(value);
              },
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            isJugadoresLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: profesorSeleccionado,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos los profesores')),
                      ...profesores,
                    ],
                    onChanged: (value) => setState(() => profesorSeleccionado = value),
                    decoration: const InputDecoration(
                      labelText: 'Profesor',
                      border: OutlineInputBorder(),
                    ),
                  ),
          ],
        );

      case 'apoderados':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar apoderados:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: categoriaSeleccionada,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
                ...categorias,
              ],
              onChanged: (value) => setState(() => categoriaSeleccionada = value),
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: apoderadoSeleccionado,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos los apoderados')),
                ...apoderados,
              ],
              onChanged: (value) => setState(() => apoderadoSeleccionado = value),
              decoration: const InputDecoration(
                labelText: 'Apoderado',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );

      default:
        return const Center(child: Text('No hay filtros disponibles para este reporte'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros del reporte'),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFiltros(),
                  const SizedBox(height: 24),
                  GradientButton(
                    child: const Text('Generar reporte PDF'),
                    onPressed: () {
                      final Map<String, dynamic> filtros = {
                        if (categoriaSeleccionada != null) 'categoria': categoriaSeleccionada,
                        if (jugadorSeleccionado != null) 'jugador': jugadorSeleccionado,
                        if (profesorSeleccionado != null) 'profesor': profesorSeleccionado,
                        if (apoderadoSeleccionado != null) 'apoderado': apoderadoSeleccionado,
                        if (fechaInicio != null) 'fechaInicio': fechaInicio!.toIso8601String(),
                        if (fechaFin != null) 'fechaFin': fechaFin!.toIso8601String(),
                      };
                      debugPrint('Filtros enviados al reporte: $filtros');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportesPdfPreviewScreen(
                            tipoReporte: widget.tipoReporte,
                            filtros: filtros.isEmpty ? null : filtros,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}