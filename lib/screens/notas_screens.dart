// lib/screens/notas_screen.dart
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/nota.dart';
import '../services/nota_api_service.dart';
import '../services/usuario_api_service.dart';
import '../theme/app_colors.dart';
import 'nota_detail_screen.dart';

class NotasScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api;

  const NotasScreen({
    super.key,
    required this.usuario,
    required this.api,
  });

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  late final NotasApiService _notasService;

  bool _cargando = false;
  String? _error;
  List<Nota> _notas = [];

  @override
  void initState() {
    super.initState();
    _notasService = NotasApiService(widget.api.dio);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarNotas());
  }

  Future<void> _cargarNotas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista =
          await _notasService.obtenerNotasUsuario(widget.usuario.uid);
      setState(() {
        _notas = lista;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _abrirNuevaNota() async {
    final creada = await Navigator.of(context).push<Nota>(
      MaterialPageRoute(
        builder: (_) => NotaDetalleScreen(
          usuario: widget.usuario,
          api: widget.api,
          notaInicial: null,
        ),
      ),
    );

    if (creada != null) {
      setState(() {
        _notas.insert(0, creada);
      });
    }
  }

  Future<void> _abrirEditarNota(Nota nota) async {
    final resultado = await Navigator.of(context).push<Nota?>(
      MaterialPageRoute(
        builder: (_) => NotaDetalleScreen(
          usuario: widget.usuario,
          api: widget.api,
          notaInicial: nota,
        ),
      ),
    );

    if (resultado == null) {
      await _cargarNotas();
      return;
    }

    setState(() {
      final idx = _notas.indexWhere((n) => n.id == resultado.id);
      if (idx != -1) {
        _notas[idx] = resultado;
      }
    });
  }

  Future<void> _confirmarEliminarTodas() async {
    if (_notas.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar todas las notas'),
          content: const Text(
            'Se borrarán TODAS las notas de tu lista.\n\n'
            'Esta acción es permanente y no se puede deshacer.\n'
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
                'Eliminar todo',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _notasService.eliminarTodasNotas(userId: widget.usuario.uid);
      if (!mounted) return;
      setState(() {
        _notas.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se eliminaron todas las notas'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.usuario.nombre},',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              '¿Qué hay de nuevo?',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Image(
                image: AssetImage('assets/images/MiEduRitmo_Negro.png'),
                height: 28,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  color: Colors.red,
                  tooltip: 'Borrar todas las notas',
                  onPressed: _notas.isEmpty ? null : _confirmarEliminarTodas,
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _abrirNuevaNota,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0066FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildContenido(),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_notas.isEmpty) {
      return const Center(
        child: Text(
          'No tienes notas registradas',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        itemCount: _notas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, index) {
          final nota = _notas[index];
          return GestureDetector(
            onTap: () => _abrirEditarNota(nota),
            child: _buildNotaCard(nota, index),
          );
        },
      ),
    );
  }

  Widget _buildNotaCard(Nota nota, int index) {
    // 3 degradados para rotar
    final gradients = <List<Color>>[
      [const Color(0xFFF20000), const Color.fromARGB(255, 248, 62, 62)], 
      [const Color(0xFF1782C6), const Color.fromARGB(255, 75, 169, 227)], 
      [const Color(0xFF8ACB27), const Color.fromARGB(255, 190, 234, 124)], 
      [const Color(0xFF6B4E91), const Color.fromARGB(255, 161, 109, 228)], 
      [const Color(0xFFFFCB3A), const Color.fromARGB(255, 234, 198, 99)], 
      [const Color(0xFFFC8A27), const Color.fromARGB(255, 250, 161, 84)], 
    ];
    final colors = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nota.nombreNota,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nota.contenidoNota.isEmpty
                ? 'Sin contenido'
                : nota.contenidoNota,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
