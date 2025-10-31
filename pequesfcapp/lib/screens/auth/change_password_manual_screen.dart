import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/profesor_model.dart';

class ChangePasswordManualScreen extends StatefulWidget {
  final ProfesorModel profesor;
  const ChangePasswordManualScreen({Key? key, required this.profesor}) : super(key: key);

  @override
  State<ChangePasswordManualScreen> createState() => _ChangePasswordManualScreenState();
}

class _ChangePasswordManualScreenState extends State<ChangePasswordManualScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar contraseña actual contra el campo del modelo (manual)
    if (_currentCtrl.text.trim() != widget.profesor.contrasena) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actual incorrecta')));
      return;
    }

    setState(() => _loading = true);
    try {
      final newPass = _newCtrl.text.trim();
      // Actualizar en Firestore (colección 'usuarios', doc id = profesor.id)
      await FirebaseFirestore.instance.collection('usuarios').doc(widget.profesor.id).update({
        'contrasena': newPass,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa la contraseña actual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                validator: (v) => (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
                validator: (v) => v != _newCtrl.text ? 'No coincide' : null,
              ),
              const SizedBox(height: 20),
              _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _updatePassword, child: const Text('Actualizar contraseña')),
            ],
          ),
        ),
      ),
    );
  }
}