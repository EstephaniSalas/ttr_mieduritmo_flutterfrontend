// lib/screens/horario_screen.dart
import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../models/usuario.dart';
import 'calendario_screen.dart';
import '../services/materia_api_service.dart';
import '../services/usuario_api_service.dart';
import '../theme/app_colors.dart';
import 'add_materia_sheet.dart';

import '../widgets/main_app_bar.dart';

class HorarioScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api; // Token

  const HorarioScreen({
    super.key,
    required this.usuario,
    required this.api,
  });

  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  late final MateriasService _materiasService;
  late Usuario _usuario; 

  bool _loading = false;
  String? _error;
  List<Materia> _materias = [];

  // 0 = Horario escolar, 1 = Calendario (por ahora solo cambia el toggle visual)
  int _modeIndex = 0;

  // Días columnas
  final List<String> _dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

  final Map<String, String> _mapDiaCompleto = const {
    'Lun': 'Lunes',
    'Mar': 'Martes',
    'Mie': 'Miercoles',
    'Jue': 'Jueves',
    'Vie': 'Viernes',
    'Sab': 'Sábado',
    'Dom': 'Domingo',
  };

  // Rango horario dinámico
  int _startHour = 7;
  int _endHour = 18;
  static const double _slotHeight = 64.0;

  // Colores
  final Map<String, Color> _colorCache = {};
  final List<Color> _palette = const [
    AppColors.red,
    AppColors.orange,
    AppColors.yellow,
    AppColors.green,
    AppColors.blue,
    AppColors.purple,
  ];
  int _nextColorIndex = 0;

  Color _variantColor(Color base, int variantIndex) {
    if (variantIndex <= 0) return base;

    final hsl = HSLColor.fromColor(base);

    final step = 0.10;
    final sign = (variantIndex % 2 == 1) ? 1.0 : -1.0;
    final magnitude = (1 + variantIndex ~/ 2) * step;

    final newLightness = (hsl.lightness + sign * magnitude).clamp(0.25, 0.80);

    return hsl.withLightness(newLightness).toColor();
  }

  double get _timelineHeight => (_endHour - _startHour) * _slotHeight;

  @override
  void initState() {
    super.initState();
    _materiasService = MateriasService(widget.api.dio);
    _usuario = widget.usuario;
  }

  /// Recargar datos siempre que entras al tab
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaterias();
    });
  }

  Future<void> _loadMaterias() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final materias =
          await _materiasService.getMateriasUsuario(widget.usuario.uid);

      setState(() {
        _materias = materias;
        _recalculateHourRange();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Helpers -------------------------------------------------------

  int _hhmmToMinutes(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  Color _colorForMateria(String id) {
    if (_colorCache.containsKey(id)) return _colorCache[id]!;

    final index = _nextColorIndex++;

    final baseIndex = index % _palette.length;
    final variantIndex = index ~/ _palette.length;

    final baseColor = _palette[baseIndex];
    final color = _variantColor(baseColor, variantIndex);

    _colorCache[id] = color;
    return color;
  }

  void _recalculateHourRange() {
    if (_materias.isEmpty) {
      _startHour = 7;
      _endHour = 18;
      return;
    }

    int minHour = 23;
    int maxHour = 0;

    for (final m in _materias) {
      for (final h in m.horarios) {
        final sMin = _hhmmToMinutes(h.horaInicio);
        final eMin = _hhmmToMinutes(h.horaFin);

        final sHour = sMin ~/ 60;
        final eHour = (eMin + 59) ~/ 60;

        if (sHour < minHour) minHour = sHour;
        if (eHour > maxHour) maxHour = eHour;
      }
    }

    if (minHour >= maxHour) {
      minHour = 7;
      maxHour = 18;
    }

    _startHour = minHour.clamp(0, 23);
    _endHour = maxHour.clamp(_startHour + 1, 23);
  }

  // Registrar materia --------------------------------------------

  Future<void> _openAddMateriaSheet() async {
    final nueva = await showModalBottomSheet<Materia?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: AddMateriaSheet(
            materiaInicial: null,
            onSubmit: (payload) async {
              return await _materiasService.crearMateria(
                userId: widget.usuario.uid,
                nombreMateria: payload.nombre,
                profesorMateria: payload.profesor,
                edificioMateria: payload.edificio,
                salonMateria: payload.salon,
                horarios: payload.horarios,
              );
            },
          ),
        );
      },
    );

    if (nueva != null && mounted) {
      setState(() {
        _materias.add(nueva);
        _recalculateHourRange();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Materia creada correctamente"),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  // Editar materia ----------------------------------------------

  Future<void> _openEditMateriaSheet(Materia materia) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: AddMateriaSheet(
            materiaInicial: materia,
            onSubmit: (payload) async {
              return await _materiasService.actualizarMateria(
                userId: widget.usuario.uid,
                materiaId: materia.id,
                nombreMateria: payload.nombre,
                profesorMateria: payload.profesor,
                edificioMateria: payload.edificio,
                salonMateria: payload.salon,
                horarios: payload.horarios,
              );
            },
            onDelete: () async {
              await _materiasService.eliminarMateria(
                userId: widget.usuario.uid,
                materiaId: materia.id,
              );
            },
          ),
        );
      },
    );

    if (!mounted) return;

    if (result is Materia) {
      setState(() {
        final i = _materias.indexWhere((m) => m.id == result.id);
        if (i != -1) _materias[i] = result;
        _recalculateHourRange();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materia actualizada correctamente'),
          backgroundColor: AppColors.green,
        ),
      );
    } else if (result == 'deleted') {
      setState(() {
        _materias.removeWhere((m) => m.id == materia.id);
        _recalculateHourRange();
      });

      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            content: const Text("Materia eliminada exitosamente"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Aceptar"),
              )
            ],
          );
        },
      );
    }
  }

  // UI ------------------------------------------------------------

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    appBar: MainAppBar(
      usuario: _usuario,                 
      api: widget.api,
      subtitle: "Así se ve tu semana",
      onUsuarioActualizado: (nuevoUsuario) {
        setState(() {
          _usuario = nuevoUsuario;       
        });
      },
    ),
    body: Column(
      children: [
        const SizedBox(height: 12),
        _buildModeToggle(theme),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Horario escolar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed:
                    _materias.isEmpty ? null : () => _confirmDeleteAll(),
              ),
              InkWell(
                onTap: _openAddMateriaSheet,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0066FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildContent()),
      ],
    ),
  );
}

  Widget _buildModeToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF3),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildToggleButton("Horario escolar", 0),
            const SizedBox(width: 4),
            _buildToggleButton("Calendario", 1),
          ],
        ),
      ),
    );
  }

// Dentro de _buildModeToggle() de HorarioScreen
  Widget _buildToggleButton(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            // Ya estás en Horario escolar, solo actualiza _modeIndex si lo usas
            setState(() => _modeIndex = 0);
          } else if (index == 1) {
            // Calendario: misma sección, sin animación de cambio de pantalla
            setState(() => _modeIndex = 1);
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => CalendarioScreen(
                  usuario: widget.usuario,
                  api: widget.api,
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _modeIndex == index ? AppColors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _modeIndex == index
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: _modeIndex == index ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        child: SizedBox(
          height: _timelineHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHourColumn(),
              const SizedBox(width: 4),
              for (final d in _dias) _buildDayColumn(d),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourColumn() {
    final totalHours = _endHour - _startHour;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: 52,
      child: Column(
        children: List.generate(totalHours + 1, (i) {
          final hour = _startHour + i;
          return SizedBox(
            height: _slotHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                "${hour.toString().padLeft(2, '0')}:00",
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(String diaAbrev) {
    final diaCompleto = _mapDiaCompleto[diaAbrev]!;
    final totalHours = _endHour - _startHour;

    final bloques = <_BloqueMateria>[];

    for (final m in _materias) {
      for (final h in m.horarios) {
        if (h.dia != diaCompleto) continue;

        final sMin = _hhmmToMinutes(h.horaInicio);
        final eMin = _hhmmToMinutes(h.horaFin);

        final dayStart = _startHour * 60;
        final dayEnd = _endHour * 60;

        final startClamped = sMin.clamp(dayStart, dayEnd);
        final endClamped = eMin.clamp(dayStart, dayEnd);

        if (endClamped <= startClamped) continue;

        final top = ((startClamped - dayStart) / 60.0) * _slotHeight;
        final height = ((endClamped - startClamped) / 60.0) * _slotHeight;

        bloques.add(
          _BloqueMateria(
            materia: m,
            top: top,
            height: height,
          ),
        );
      }
    }

    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: Center(
              child: Text(
                diaAbrev,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SizedBox(
              height: totalHours * _slotHeight,
              child: Stack(
                children: [
                  for (final b in bloques)
                    Positioned(
                      top: b.top,
                      left: 2,
                      right: 2,
                      height: b.height,
                      child: GestureDetector(
                        onTap: () => _openEditMateriaSheet(b.materia),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _colorForMateria(b.materia.id),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.materia.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (b.materia.salon.isNotEmpty ||
                                  b.materia.edificio.isNotEmpty)
                                Text(
                                  [
                                    if (b.materia.edificio.isNotEmpty)
                                      "Edif. ${b.materia.edificio}",
                                    if (b.materia.salon.isNotEmpty)
                                      "Salón ${b.materia.salon}",
                                  ].join(" · "),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll() async {
    if (_materias.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Eliminar todas las materias"),
          content: const Text(
            "Se borrarán TODAS las materias del horario.\n"
            "Esta acción es permanente.\n"
            "¿Continuar?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                "Eliminar todo",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _materiasService.eliminarTodasLasMaterias(
        userId: widget.usuario.uid,
      );

      if (!mounted) return;

      setState(() {
        _materias.clear();
        _recalculateHourRange();
      });

      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            content: const Text("Se eliminaron todas las materias"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Aceptar"),
              ),
            ],
          );
        },
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

// Clase interna
class _BloqueMateria {
  final Materia materia;
  final double top;
  final double height;

  _BloqueMateria({
    required this.materia,
    required this.top,
    required this.height,
  });
}
