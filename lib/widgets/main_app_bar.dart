import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_api_service.dart';
import '../screens/login_screen.dart';
import '../screens/editar_usuario_screen.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Usuario usuario;
  final UsuarioApiService api;
  final String subtitle;

  /// Nuevo: callback para notificar que el usuario fue actualizado
  final ValueChanged<Usuario> onUsuarioActualizado;

  const MainAppBar({
    super.key,
    required this.usuario,
    required this.api,
    required this.subtitle,
    required this.onUsuarioActualizado,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () => _abrirMenuUsuario(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Buen día, ${usuario.nombre}",
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Image(
            image: AssetImage('assets/images/MiEduRitmo_Negro.png'),
            height: 28,
          ),
        )
      ],
    );
  }

  Future<void> _abrirMenuUsuario(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Modificar mis datos'),
                onTap: () async {
                  Navigator.pop(ctx); // cerrar el bottom sheet

                  final actualizado = await Navigator.push<Usuario>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarUsuarioScreen(
                        usuario: usuario,
                        api: api,
                      ),
                    ),
                  );

                  if (actualizado != null) {
                    // Notificar a la pantalla padre para que haga setState
                    onUsuarioActualizado(actualizado);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);

                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text(
                          '¿Quieres cerrar sesión en la aplicación?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  );

                  if (confirmar != true) return;

                  await api.logout();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(api: api),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
