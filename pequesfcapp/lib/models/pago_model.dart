import 'package:cloud_firestore/cloud_firestore.dart';

class PagoModel {
  final String id;
  final String jugadorId;
  final DateTime fechaPago;
  final double monto;
  final String mes;
  final int anio;
  final String estado;
  final String? observacion;

  PagoModel({
    required this.id,
    required this.jugadorId,
    required this.fechaPago,
    required this.monto,
    required this.mes,
    required this.anio,
    required this.estado,
    this.observacion,
  });

  factory PagoModel.fromMap(Map<String, dynamic> map) => PagoModel(
    id: map['id'] ?? '',
    jugadorId: map['jugadorId'] ?? '',
    fechaPago: (map['fechaPago'] as Timestamp).toDate(),
    monto: (map['monto'] as num).toDouble(),
    mes: map['mes'] ?? '',
    anio: map['anio'] ?? 0,
    estado: map['estado'] ?? 'pendiente',
    observacion: map['observacion'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'jugadorId': jugadorId,

    'fechaPago': Timestamp.fromDate(fechaPago),
    'monto': monto,
    'mes': mes,
    'anio': anio,
    'estado': estado,
    'observacion': observacion,
  };
}