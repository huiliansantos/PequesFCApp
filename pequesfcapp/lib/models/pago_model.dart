import 'package:cloud_firestore/cloud_firestore.dart';

class PagoModel {
  final String id;
  final String jugadorId;
  final DateTime fechaPago;
  final double monto;
  final String mes;
  final String estado; // 'pagado', 'pendiente', 'atrasado'
  final String? observacion;

  PagoModel({
    required this.id,
    required this.jugadorId,
    required this.fechaPago,
    required this.monto,
    required this.mes,
    required this.estado,
    this.observacion,
  });

  factory PagoModel.fromMap(Map<String, dynamic> map) => PagoModel(
    id: map['id'] ?? '',
    jugadorId: map['jugadorId'] ?? '',
    fechaPago: (map['fechaPago'] as Timestamp).toDate(),
    monto: (map['monto'] as num).toDouble(),
    mes: map['mes'] ?? '',
    estado: map['estado'] ?? 'pendiente',
    observacion: map['observacion'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'jugadorId': jugadorId,

    'fechaPago': Timestamp.fromDate(fechaPago),
    'monto': monto,
    'mes': mes,
    'estado': estado,
    'observacion': observacion,
  };
}