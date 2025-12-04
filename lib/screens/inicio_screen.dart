import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_api_service.dart';

class InicioScreen extends StatelessWidget {
  final Usuario usuario;
  final UsuarioApiService api;

  const InicioScreen({
    super.key,
    required this.usuario,
    required this.api,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, ${usuario.nombre}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              "Bienvenido",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),

      body: const Center(
        child: Text("Inicio"),
      ),
    );
  }
}
