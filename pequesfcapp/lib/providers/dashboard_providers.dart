import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _db = FirebaseFirestore.instance;

// Documento con info del club (ajusta collection/doc si tu proyecto usa otra ruta)
final teamInfoProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return _db.collection('config').doc('club').snapshots().map((snap) {
    if (!snap.exists) return <String, dynamic>{};
    final data = snap.data()!;
    return {
      'name': (data['name'] ?? data['clubName'] ?? 'Peques F.C.').toString(),
      'founding': (data['founding'] ?? 'Marzo 2014').toString(),
      'categories': (data['categories'] ?? 'Niños de 3 años para adelante').toString(),
      'training': (data['training'] ?? 'Lunes a viernes — Mañana y tarde').toString(),
      'location': (data['location'] ?? 'Barrio SENAC / Complejo Deportivo García Ágreda').toString(),
      'logoUrl': (data['logoUrl'] ?? '').toString(),
    };
  });
});

// Conteos (ajusta nombres de colecciones si usas otros)
final playersCountProvider = StreamProvider<int>((ref) {
  return _db.collection('jugadores').snapshots().map((s) => s.size);
});

final coachesCountProvider = StreamProvider<int>((ref) {
  // Si tienes colección 'profesores' úsala; si no, cambia aquí
  return _db.collection('profesores').snapshots().map((s) => s.size);
});

final matchesCountProvider = StreamProvider<int>((ref) {
  return _db.collection('partidos').snapshots().map((s) => s.size);
});

final resultsCountProvider = StreamProvider<int>((ref) {
  return _db.collection('resultados').snapshots().map((s) => s.size);
});