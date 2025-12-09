import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_api_service.dart';

class EditarUsuarioScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api;

  const EditarUsuarioScreen({
    super.key,
    required this.usuario,
    required this.api,
  });

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  final TextEditingController _passActualCtrl = TextEditingController();
  final TextEditingController _passNuevaCtrl = TextEditingController();
  final TextEditingController _passNueva2Ctrl = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.usuario.nombre);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    _passNueva2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    final passActual = _passActualCtrl.text.trim();
    final passNueva = _passNuevaCtrl.text.trim();
    final passNueva2 = _passNueva2Ctrl.text.trim();

    // Si no hay ningún cambio, no pegues a la API
    if (nombre.isEmpty &&
        passActual.isEmpty &&
        passNueva.isEmpty &&
        passNueva2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cambios para guardar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validación adicional de contraseñas: si quiere cambiar, que llene las 3
    final quiereCambiarPass =
        passActual.isNotEmpty || passNueva.isNotEmpty || passNueva2.isNotEmpty;

    if (quiereCambiarPass) {
      if (passActual.isEmpty || passNueva.isEmpty || passNueva2.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Para cambiar la contraseña debes llenar los tres campos.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final actualizado = await widget.api.actualizarUsuario(
        id: widget.usuario.uid, 
        nombre: nombre.isEmpty ? widget.usuario.nombre : nombre,
        passwordActual: quiereCambiarPass ? passActual : null,
        passwordNueva: quiereCambiarPass ? passNueva : null,
        passwordNueva2: quiereCambiarPass ? passNueva2 : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario actualizado correctamente.'),
        ),
      );

      // regresamos el usuario actualizado a la pantalla anterior
      Navigator.pop(context, actualizado);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar usuario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis datos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Datos básicos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v != null && v.isEmpty) {
                    return 'El nombre no puede estar vacío';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Cambiar contraseña (opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passActualCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passNuevaCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passNueva2Ctrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Repetir nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_passNuevaCtrl.text.isNotEmpty ||
                      _passNueva2Ctrl.text.isNotEmpty ||
                      _passActualCtrl.text.isNotEmpty) {
                    if (_passNuevaCtrl.text.length < 8 ||
                        _passNueva2Ctrl.text.length < 8) {
                      return 'La nueva contraseña debe tener al menos 8 caracteres';
                    }
                    if (_passNuevaCtrl.text != _passNueva2Ctrl.text) {
                      return 'Las contraseñas nuevas no coinciden';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _guardar,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
