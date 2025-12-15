import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_api_service.dart';
import '../screens/login_screen.dart';
import '../screens/editar_usuario_screen.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Usuario usuario;
  final UsuarioApiService api;
  final String subtitle;

  /// Callback para notificar que el usuario fue actualizado
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

  static const String _avisoLegalTexto =
      '⚠️  Deslinde de Responsabilidad\n'
      'Esta app es una herramienta de apoyo, no un\n'
      'garante de obligaciones académicas.\n\n'
      '🔒  Aviso de Privacidad y Uso\n'
      '- No nos hacemos responsables por mal uso de la\n'
      '  información o fallos del dispositivo.\n'
      '- La responsabilidad final recae en el estudiante.\n\n'
      '📅  Datos de Terceros\n'
      'La información del calendario SEP es referencial\n'
      'y respeta la autoría oficial.';

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () => _abrirPanelLateral(context),
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

  Future<void> _abrirPanelLateral(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: 'menu_usuario',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.78,
                height: double.infinity,
                color: Colors.white,
                child: Column(
                  children: [
                    // Header negro
                    Container(
                      height: 110,
                      width: double.infinity,
                      color: Colors.black,
                      padding: const EdgeInsets.only(left: 4, right: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          const Spacer(),
                          const Image(
                            image: AssetImage('assets/images/MiEduRitmo_Negro.png'),
                            height: 32,
                            // Nota: si tu logo negro se pierde en fondo negro,
                            // cambia a versión blanca o quita el logo aquí.
                          ),
                        ],
                      ),
                    ),

                    // Contenido (Avisos legales)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'MiEduRitmo - Avisos Legales',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 12),
                            _LegalBlock(texto: _avisoLegalTexto),
                          ],
                        ),
                      ),
                    ),

                    // Botones inferiores
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE9E9E9),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              icon: const Icon(Icons.person,
                                  color: Colors.black87),
                              label: const Text(
                                'Modificar datos',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop(); // cerrar panel

                                final actualizado =
                                    await Navigator.push<Usuario>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarUsuarioScreen(
                                      usuario: usuario,
                                      api: api,
                                    ),
                                  ),
                                );

                                if (actualizado != null) {
                                  onUsuarioActualizado(actualizado);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text(
                                'Cerrar sesión',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop(); // cerrar panel

                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    title: const Text('Cerrar sesión'),
                                    content: const Text(
                                      '¿Quieres cerrar sesión en la aplicación?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dCtx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dCtx, true),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return SlideTransition(position: offset, child: child);
      },
    );
  }
}

class _LegalBlock extends StatelessWidget {
  final String texto;
  const _LegalBlock({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.35,
        color: Colors.black87,
      ),
    );
  }
}
