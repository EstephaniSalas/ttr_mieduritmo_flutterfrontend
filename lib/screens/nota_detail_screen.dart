// lib/screens/nota_detalle_screen.dart
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/nota.dart';
import '../services/nota_api_service.dart';
import '../services/usuario_api_service.dart';
import '../theme/app_colors.dart';

class NotaDetalleScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api;
  final Nota? notaInicial;

  const NotaDetalleScreen({
    super.key,
    required this.usuario,
    required this.api,
    this.notaInicial,
  });

  @override
  State<NotaDetalleScreen> createState() => _NotaDetalleScreenState();
}

class _NotaDetalleScreenState extends State<NotaDetalleScreen> {
  late final NotasApiService _notasService;

  final _tituloCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();

  bool _guardando = false;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _notasService = NotasApiService(widget.api.dio);

    if (widget.notaInicial != null) {
      _tituloCtrl.text = widget.notaInicial!.nombreNota;
      _contenidoCtrl.text = widget.notaInicial!.contenidoNota;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _contenidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarNota() async {
    final titulo = _tituloCtrl.text.trim();
    final contenido = _contenidoCtrl.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título de la nota es obligatorio'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      Nota notaResult;

      if (widget.notaInicial == null) {
        notaResult = await _notasService.crearNota(
          userId: widget.usuario.uid,
          nombreNota: titulo,
          contenidoNota: contenido,
        );
      } else {
        notaResult = await _notasService.actualizarNota(
          userId: widget.usuario.uid,
          notaId: widget.notaInicial!.id,
          nombreNota: titulo,
          contenidoNota: contenido,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.notaInicial == null
              ? 'Nota creada correctamente'
              : 'Nota actualizada correctamente'),
          backgroundColor: AppColors.green,
        ),
      );

      Navigator.of(context).pop<Nota>(notaResult);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminar() async {
    if (widget.notaInicial == null) {
      Navigator.of(context).pop();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar nota'),
          content: const Text(
            'Esta acción eliminará la nota de forma permanente.\n\n'
            '¿Quieres continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;
    await _eliminarNota();
  }

  Future<void> _eliminarNota() async {
    if (widget.notaInicial == null) return;

    setState(() {
      _eliminando = true;
    });

    try {
      await _notasService.eliminarNota(
        userId: widget.usuario.uid,
        notaId: widget.notaInicial!.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nota eliminada'),
          backgroundColor: AppColors.green,
        ),
      );

      Navigator.of(context).pop<Nota?>(null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _eliminando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNueva = widget.notaInicial == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _NotebookLinesPainter(),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: 0.08,
                      child: Image.asset(
                        'assets/images/MiEduRitmo_Negro.png',
                        width: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo título arriba
                      TextField(
                        controller: _tituloCtrl,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Título nota',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const Divider(thickness: 1, height: 24),
                      // Campo contenido
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: TextField(
                          controller: _contenidoCtrl,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Contenido nota.',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarNota,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Guardar nota',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!esNueva)
                  TextButton(
                    onPressed: _eliminando ? null : _confirmarEliminar,
                    child: _eliminando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Eliminar nota',
                            style: TextStyle(color: Colors.red),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor para las líneas del "cuaderno"
class _NotebookLinesPainter extends CustomPainter {
  final Paint _linePaint = Paint()
    ..color = const Color(0xFFE0E0E0)
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    const double lineSpacing = 32.0;
    double y = 64; // dejar espacio arriba (título)

    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _linePaint);
      y += lineSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
