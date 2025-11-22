import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;  // ✅ CORREGIDO: Hacerlo nullable
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;  // ✅ Detectar si está habilitado

    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? const [Color(0xFFD32F2F), Color(0xFFF57C00)]
                : [Colors.grey.shade400, Colors.grey.shade500],  // ✅ Color gris cuando está deshabilitado
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,  // ✅ Automáticamente será null si está deshabilitado
          child: Container(
            padding: padding,
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white70,  // ✅ Texto más claro cuando deshabilitado
                fontWeight: FontWeight.bold,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}