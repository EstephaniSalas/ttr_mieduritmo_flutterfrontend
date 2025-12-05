// lib/screens/estudio_screen.dart
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/materia.dart';
import '../services/usuario_api_service.dart';
import '../services/materia_api_service.dart';
import '../services/flashcard_api_service.dart';
import '../theme/app_colors.dart';
import 'flashcards_config_screen.dart';

class EstudioScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api;

  const EstudioScreen({
    super.key,
    required this.usuario,
    required this.api,
  });

  @override
  State<EstudioScreen> createState() => _EstudioScreenState();
}

class _EstudioScreenState extends State<EstudioScreen> {
  late final MateriasService _materiasService;
  late final FlashcardsService _flashcardsService;

  bool _cargando = false;
  String? _error;

  /// Todas las materias del usuario (para el selector del botón +)
  List<Materia> _materiasUsuario = [];

  /// Materias que se mostrarán en la grilla (las que tienen flashcards)
  List<Materia> _materiasFlashcards = [];

  @override
  void initState() {
    super.initState();
    _materiasService = MateriasService(widget.api.dio);
    _flashcardsService = FlashcardsService(widget.api.dio);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // 1) materias del usuario (esto sí es crítico)
      final materiasUsuario =
          await _materiasService.getMateriasUsuario(widget.usuario.uid);

      // 2) materias con flashcards (si falla, seguimos pero con lista vacía)
      List<Materia> materiasConFlashcards = [];
      try {
        materiasConFlashcards =
            await _flashcardsService.obtenerMateriasConFlashcards(
          userId: widget.usuario.uid,
        );
      } catch (_) {
        materiasConFlashcards = [];
      }

      setState(() {
        _materiasUsuario = materiasUsuario;
        _materiasFlashcards = materiasConFlashcards;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  /// Selector que se abre al pulsar el botón +
  Future<void> _seleccionarMateriaDesdeBoton() async {
    if (_materiasUsuario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero registra materias en Horario/Tareas'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final materiaSeleccionada = await showModalBottomSheet<Materia>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona la materia para crear/editar flashcards',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _materiasUsuario.length,
                  itemBuilder: (context, index) {
                    final m = _materiasUsuario[index];
                    return ListTile(
                      title: Text(
                        m.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(ctx).pop(m),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (materiaSeleccionada == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardsConfigScreen(
          usuario: widget.usuario,
          materia: materiaSeleccionada,
          api: widget.api,
        ),
      ),
    );

    // Al volver, intento refrescar solo las materias con flashcards
    try {
      final materiasConFlashcards =
          await _flashcardsService.obtenerMateriasConFlashcards(
        userId: widget.usuario.uid,
      );
      if (!mounted) return;
      setState(() {
        _materiasFlashcards = materiasConFlashcards;
      });
    } catch (_) {
      // si falla, dejamos la lista como estaba
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
              widget.usuario.nombre,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              '¿Qué repasaremos?',
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Flashcards',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever),
                color: Colors.red,
                tooltip: 'Borrar todas las flashcards',
                onPressed: _confirmarBorrarTodasFlashcards,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Colors.blue,
                tooltip: 'Agregar materia a flashcards',
                onPressed: _seleccionarMateriaDesdeBoton,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Recomendación.\n'
            'El método Pomodoro es un sistema de estudio con pausas que divide el tiempo en bloques de 25 minutos de concentración intensa, '
            'seguido de descansos cortos. Usa las flashcards para repasar de forma constante.',
            style: TextStyle(
              fontSize: 12,
              color: Color.fromARGB(221, 94, 94, 94),
            ),
          ),
          const SizedBox(height: 16),
          _buildMateriasGrid(),
          const SizedBox(height: 24),
          _buildTiempoEstudioCard(),
        ],
      ),
    );
  }

  /// Grid 2×N de materias con flashcards
  Widget _buildMateriasGrid() {
    if (_materiasFlashcards.isEmpty) {
      return const Text(
        'Aún no has agregado materias a Flashcards.\nPulsa el botón + para comenzar.',
        style: TextStyle(color: Colors.black54),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - 16 * 2 - 8) / 2;

    final colores = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.red,
      Colors.cyan,
      Colors.purple,
      Colors.teal,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: List.generate(_materiasFlashcards.length, (index) {
        final m = _materiasFlashcards[index];
        final color = colores[index % colores.length];

        return SizedBox(
          width: itemWidth,
          height: 48,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FlashcardsConfigScreen(
                    usuario: widget.usuario,
                    materia: m,
                    api: widget.api,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                m.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTiempoEstudioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Tiempo de estudio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Esta gráfica mostrará el tiempo dedicado al repaso de las flashcards por día.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'Gráfica de tiempo de estudio\n(Pendiente conectar con sesiones)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarBorrarTodasFlashcards() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar todas las flashcards'),
          content: const Text(
            'Se eliminarán TODAS las flashcards registradas para este usuario.\n\n'
            'Esta acción es permanente.\n'
            '¿Deseas continuar?',
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
      await _flashcardsService.eliminarTodasFlashcardsUsuario(
        userId: widget.usuario.uid,
      );
      if (!mounted) return;

      setState(() {
        _materiasFlashcards.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se eliminaron todas las flashcards'),
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
}
