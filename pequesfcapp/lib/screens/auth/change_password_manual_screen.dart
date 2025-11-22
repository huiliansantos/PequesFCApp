import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/guardian_model.dart';
import '../../models/profesor_model.dart';
import '../../widgets/gradient_button.dart';
import '../../services/auth_service.dart';

class ChangePasswordManualScreen extends StatefulWidget {
  final dynamic usuario; // GuardianModel o ProfesorModel

  const ChangePasswordManualScreen({Key? key, required this.usuario})
      : super(key: key);

  @override
  State<ChangePasswordManualScreen> createState() =>
      _ChangePasswordManualScreenState();
}

class _ChangePasswordManualScreenState
    extends State<ChangePasswordManualScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController contrasenaActualController;
  late TextEditingController contrasenaNewController;
  late TextEditingController contrasenaConfirmController;

  bool _obscureActual = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  late String coleccion;
  late String docId;
  late String contrasenaActual;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setCollectionAndDocId();
  }

  void _initializeControllers() {
    contrasenaActualController = TextEditingController();
    contrasenaNewController = TextEditingController();
    contrasenaConfirmController = TextEditingController();
  }

  void _setCollectionAndDocId() {
    if (widget.usuario is ProfesorModel) {
      final profesor = widget.usuario as ProfesorModel;
      coleccion = 'profesores';
      docId = profesor.id;
      contrasenaActual = profesor.contrasena;
      debugPrint('✅ Detectado ProfesorModel: $docId');
    } else if (widget.usuario is GuardianModel) {
      final guardian = widget.usuario as GuardianModel;
      coleccion = 'guardianes';
      docId = guardian.id;
      contrasenaActual = guardian.contrasena;
      debugPrint('✅ Detectado GuardianModel: $docId');
    } else {
      debugPrint('❌ Tipo de usuario no reconocido');
    }
  }

  @override
  void dispose() {
    contrasenaActualController.dispose();
    contrasenaNewController.dispose();
    contrasenaConfirmController.dispose();
    super.dispose();
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('⚠️ Validación del formulario fallida');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final actual = contrasenaActualController.text.trim();
      final nueva = contrasenaNewController.text.trim();
      final confirmacion = contrasenaConfirmController.text.trim();

      debugPrint('🔐 Iniciando cambio de contraseña en $coleccion/$docId');

      // Validación 1: Contraseña actual correcta
      if (actual != contrasenaActual) {
        debugPrint('❌ Contraseña actual incorrecta');
        _showErrorSnackbar('La contraseña actual es incorrecta');
        return;
      }

      // Validación 2: Nueva contraseña diferente de la actual
      if (nueva == actual) {
        debugPrint('❌ Nueva contraseña igual a la actual');
        _showErrorSnackbar(
            'La nueva contraseña debe ser diferente a la actual');
        return;
      }

      // Validación 3: Confirmación coincide
      if (nueva != confirmacion) {
        debugPrint('❌ Las contraseñas de confirmación no coinciden');
        _showErrorSnackbar('Las contraseñas no coinciden');
        return;
      }

      // Actualizar en Firestore
      debugPrint('📝 Actualizando contraseña en Firestore...');
      await FirebaseFirestore.instance
          .collection(coleccion)
          .doc(docId)
          .update({'contrasena': nueva});

      debugPrint('✅ Contraseña actualizada en Firestore');

      // ✅ Actualizar también en la sesión local
      await AuthService.actualizarContrasenaLocal(nueva);

      debugPrint('✅ Contraseña actualizada en sesión local');

      if (mounted) {
        _showSuccessSnackbar('Contraseña actualizada correctamente');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } on FirebaseException catch (e) {
      debugPrint('❌ Error Firebase: ${e.code} - ${e.message}');
      if (mounted) {
        _showErrorSnackbar('Error Firestore: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error actualizando contraseña: $e');
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
        elevation: 0,
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Actualiza tu contraseña',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por seguridad, ingresa tu contraseña actual y luego la nueva',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contraseña Actual
                  TextFormField(
                    controller: contrasenaActualController,
                    obscureText: _obscureActual,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureActual
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureActual = !_obscureActual;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nueva Contraseña
                  TextFormField(
                    controller: contrasenaNewController,
                    obscureText: _obscureNew,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      helperText: 'Mínimo 6 caracteres',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNew = !_obscureNew;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo obligatorio';
                      }
                      if (v.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirmar Contraseña
                  TextFormField(
                    controller: contrasenaConfirmController,
                    obscureText: _obscureConfirm,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo obligatorio';
                      }
                      if (v != contrasenaNewController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón Guardar
                  GradientButton(
                    onPressed: _isLoading ? null : () => _cambiarContrasena(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Actualizar Contraseña',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Info de seguridad
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      '💡 Consejo: Usa una contraseña fuerte con números, letras y caracteres especiales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}