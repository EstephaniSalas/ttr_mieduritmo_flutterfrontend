// lib/screens/estudio_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/usuario.dart';
import '../models/materia.dart';
import '../services/usuario_api_service.dart';
import '../services/materia_api_service.dart';
import '../services/flashcard_api_service.dart';
import '../services/sesion_estudio_api_service.dart';

import '../theme/app_colors.dart';
import 'flashcards_config_screen.dart';

import '../widgets/main_app_bar.dart';

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
  late final SesionEstudioApiService _sesionService;

  late Usuario _usuario; 

  bool _cargando = false;
  String? _error;

  /// Todas las materias del usuario (para el selector del botón +)
  List<Materia> _materiasUsuario = [];

  /// Materias que se mostrarán en la grilla (las que tienen flashcards)
  List<Materia> _materiasFlashcards = [];

  /// Resumen de tiempo de estudio (para la gráfica)
  List<ResumenDiaEstudio> _resumenDias = [];
  bool _cargandoResumen = false;
  String? _errorResumen;

  @override
  void initState() {
    super.initState();
    _materiasService = MateriasService(widget.api.dio);
    _flashcardsService = FlashcardsService(widget.api.dio);
    _sesionService = SesionEstudioApiService(widget.api.dio);

    _usuario = widget.usuario;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
      _cargarResumenEstudio();
    });
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    List<Materia> materiasUsuario = [];
    List<Materia> materiasConFlashcards = [];
    String? errorMensaje;

    // 1) Materias del usuario
    try {
      materiasUsuario =
          await _materiasService.getMateriasUsuario(widget.usuario.uid);
    } catch (e) {
      errorMensaje = 'Error al obtener materias del usuario:\n$e';
    }

    // 2) Materias que ya tienen flashcards
    try {
      final materias = await _flashcardsService.obtenerMateriasConFlashcards(
        userId: widget.usuario.uid,
      );
      materiasConFlashcards = materias;
    } catch (e) {
      final msg = 'Error al obtener materias con flashcards:\n$e';
      errorMensaje = errorMensaje == null ? msg : '$errorMensaje\n\n$msg';
    }

    if (!mounted) return;

    setState(() {
      _cargando = false;
      _error = errorMensaje;
      _materiasUsuario = materiasUsuario;
      _materiasFlashcards = materiasConFlashcards;
    });
  }

  /// Refresca solo las materias que tienen flashcards (después de crear/editar)
  Future<void> _refrescarMateriasConFlashcards() async {
    try {
      final materias = await _flashcardsService.obtenerMateriasConFlashcards(
        userId: widget.usuario.uid,
      );
      if (!mounted) return;
      setState(() {
        _materiasFlashcards = materias;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al actualizar materias con flashcards:\n$e';
      });
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

    // Navegar a la pantalla de configuración de flashcards
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardsConfigScreen(
          usuario: widget.usuario,
          materia: materiaSeleccionada,
          api: widget.api,
        ),
      ),
    );

    // Al volver, refrescamos materias con flashcards
    await _refrescarMateriasConFlashcards();
  }

  Future<void> _cargarResumenEstudio() async {
    setState(() {
      _cargandoResumen = true;
      _errorResumen = null;
    });

    try {
      final resumen = await _sesionService.obtenerResumenEstudio(
        userId: widget.usuario.uid,
      );
      if (!mounted) return;
      setState(() {
        _resumenDias = resumen;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorResumen = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _cargandoResumen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: MainAppBar(
        usuario: _usuario,
        api: widget.api,
        subtitle: "Tus notas",
        onUsuarioActualizado: (nuevoUsuario) {
          setState(() {
            _usuario = nuevoUsuario;
          });
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zona de error, pero sin bloquear el resto de la UI
          if (_error != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              color: Colors.red.withOpacity(0.08),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],

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
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no has agregado materias a Flashcards',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 200, 24, 24),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pulsa el botón + para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    // Colores para las tarjetas
    final List<Color> cardColors = [
      const Color(0xFF4A6FA5), // Azul
      const Color(0xFF50B848), // Verde
      const Color(0xFFF6A800), // Amarillo/naranja
      const Color(0xFFE74C3C), // Rojo
      const Color(0xFF9B59B6), // Morado
      const Color(0xFF1ABC9C), // Turquesa
      const Color(0xFFE67E22), // Naranja
      const Color(0xFF3498DB), // Azul claro
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Evita scroll interno
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas
        crossAxisSpacing: 12, // Espacio horizontal entre tarjetas
        mainAxisSpacing: 12, // Espacio vertical entre tarjetas
        childAspectRatio: 2, // Proporción ancho/alto
      ),
      itemCount: _materiasFlashcards.length,
      itemBuilder: (context, index) {
        final materia = _materiasFlashcards[index];
        final color = cardColors[index % cardColors.length];

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FlashcardsConfigScreen(
                  usuario: widget.usuario,
                  materia: materia,
                  api: widget.api,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Efecto de brillo en esquina
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Contenido de la tarjeta
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 12),

                      // Nombre de la materia
                      Text(
                        materia.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        children: [
          const Text(
            'Tiempo de estudio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Minutos dedicados al repaso de flashcards por día (últimos días).',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          if (_cargandoResumen)
            const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorResumen != null)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  _errorResumen!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
            )
          else if (_resumenDias.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Aún no hay sesiones de estudio registradas.\n'
                  'Cuando termines un repaso se mostrará aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: _buildBarChartTiempo(),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChartTiempo() {
    // Ordenar por fecha ascendente por si el backend no lo hace
    final datos = List<ResumenDiaEstudio>.from(_resumenDias)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    final maxMinutos = datos
        .map((e) => e.totalMinutos)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    final grupos = <BarChartGroupData>[];

    for (var i = 0; i < datos.length; i++) {
      final d = datos[i];
      grupos.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: d.totalMinutos,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    String _labelFecha(String iso) {
      // iso = "YYYY-MM-DD" -> "MM-DD"
      if (iso.length >= 10) {
        return iso.substring(5); // "MM-DD"
      }
      return iso;
    }

    return BarChart(
      BarChartData(
        maxY: maxMinutos == 0 ? 10 : (maxMinutos * 1.2),
        barGroups: grupos,
        gridData: FlGridData(show: true, horizontalInterval: 10),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= datos.length) {
                  return const SizedBox.shrink();
                }
                final fecha = _labelFecha(datos[index].fecha);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    fecha,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
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
