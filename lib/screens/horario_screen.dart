import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/materia.dart';
import '../models/usuario.dart';
import '../services/materia_api_service.dart';
import '../theme/app_colors.dart';
import 'add_materia_sheet.dart';

class HorarioScreen extends StatefulWidget {
  final Usuario usuario;
  final Dio dio; // usamos el mismo Dio del login (con cookie)

  const HorarioScreen({
    super.key,
    required this.usuario,
    required this.dio,
  });

  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  late final MateriasService _materiasService;

  bool _loading = false;
  String? _error;
  List<Materia> _materias = [];

  // 0 = Horario escolar, 1 = Calendario (solo visual por ahora)
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

  // Rango horario
  static const int _startHour = 7;   // 07:00
  static const int _endHour = 18;    // 18:00
  static const double _slotHeight = 64.0; // altura “1 hora” en píxeles

  // Paleta para materias
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

  double get _timelineHeight =>
      (_endHour - _startHour) * _slotHeight; // alto total del grid

  @override
  void initState() {
    super.initState();
    _materiasService = MateriasService(widget.dio);
    _loadMaterias();
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

  int _hhmmToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return h * 60 + m;
  }

  Color _colorForMateria(String materiaId) {
    if (_colorCache.containsKey(materiaId)) {
      return _colorCache[materiaId]!;
    }
    final color = _palette[_nextColorIndex % _palette.length];
    _colorCache[materiaId] = color;
    _nextColorIndex++;
    return color;
  }

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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: AddMateriaSheet(
            materiaInicial: null,
            onSubmit: (payload) async {
              final materia = await _materiasService.crearMateria(
                userId: widget.usuario.uid,
                nombreMateria: payload.nombre,
                profesorMateria: payload.profesor,
                edificioMateria: payload.edificio,
                salonMateria: payload.salon,
                horarios: payload.horarios,
              );
              return materia;
            },
          ),
        );
      },
    );

    if (!mounted) return;

    if (nueva != null) {
      setState(() {
        _materias.add(nueva);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materia creada correctamente'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: AddMateriaSheet(
            materiaInicial: materia,
            onSubmit: (payload) async {
              final updated = await _materiasService.actualizarMateria(
                userId: widget.usuario.uid,
                materiaId: materia.id,
                nombreMateria: payload.nombre,
                profesorMateria: payload.profesor,
                edificioMateria: payload.edificio,
                salonMateria: payload.salon,
                horarios: payload.horarios,
              );
              return updated; // Navigator.pop(updated) lo hará el sheet
            },
            onDelete: () async {
              await _materiasService.eliminarMateria(
                userId: widget.usuario.uid,
                materiaId: materia.id,
              );
              // Importante: el sheet debe hacer Navigator.pop('deleted')
              // después de llamar a onDelete.
            },
          ),
        );
      },
    );

    if (!mounted) return;

    if (result is Materia) {
      // Actualizada
      setState(() {
        final idx = _materias.indexWhere((m) => m.id == result.id);
        if (idx != -1) {
          _materias[idx] = result;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materia actualizada correctamente'),
          backgroundColor: AppColors.green,
        ),
      );
    } else if (result == 'deleted') {
      // Eliminada
      setState(() {
        _materias.removeWhere((m) => m.id == materia.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materia eliminada exitosamente'),
          backgroundColor: AppColors.green,
        ),
      );
    } else {
      // Por si el sheet hace la eliminación por su cuenta pero no devuelve nada:
      await _loadMaterias();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              'Buen día, ${widget.usuario.nombre}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'Así se ve tu semana',
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
          _buildModeToggle(theme),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Horario escolar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
            child: _buildContent(),
          ),
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
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _modeIndex = 0;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        _modeIndex == 0 ? AppColors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _modeIndex == 0
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
                      'Horario escolar',
                      style: TextStyle(
                        fontSize: 13,
                        color: _modeIndex == 0
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _modeIndex = 1;
                  });
                  // lugar para futura pantalla de calendario
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        _modeIndex == 1 ? AppColors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _modeIndex == 1
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
                      'Calendario',
                      style: TextStyle(
                        fontSize: 13,
                        color: _modeIndex == 1
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
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
              // columnas de días
              for (final d in _dias) _buildDayColumn(d),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourColumn() {
    final totalHours = _endHour - _startHour;

    return SizedBox(
      width: 52,
      child: Column(
        children: List.generate(totalHours + 1, (index) {
          final hour = _startHour + index;
          return SizedBox(
            height: _slotHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
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

    final materiasDelDia = <_BloqueMateria>[];

    for (final m in _materias) {
      for (final h in m.horarios) {
        if (h.dia != diaCompleto) continue;

        final startMin = _hhmmToMinutes(h.horaInicio);
        final endMin = _hhmmToMinutes(h.horaFin);

        // recorte al rango visible 07:00-18:00
        final dayStart = _startHour * 60;
        final dayEnd = _endHour * 60;
        final clampedStart = startMin.clamp(dayStart, dayEnd);
        final clampedEnd = endMin.clamp(dayStart, dayEnd);

        if (clampedEnd <= clampedStart) continue;

        final top =
            ((clampedStart - dayStart) / 60.0) * _slotHeight; // posición Y
        final height =
            ((clampedEnd - clampedStart) / 60.0) * _slotHeight; // alto tarjeta

        materiasDelDia.add(
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
          // encabezado "Lun", "Mar", etc.
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
                  // fondo opcional por hora (solo si quieres líneas guía)
                  // for (int i = 0; i < totalHours; i++)
                  //   Positioned(
                  //     top: i * _slotHeight,
                  //     left: 0,
                  //     right: 0,
                  //     child: Container(
                  //       height: 1,
                  //       color: Colors.grey.withOpacity(0.1),
                  //     ),
                  //   ),

                  // bloques de materias
                  for (final b in materiasDelDia)
                    Positioned(
                      top: b.top,
                      left: 2,
                      right: 2,
                      height: b.height,
                      child: GestureDetector(
                        onTap: () => _openEditMateriaSheet(b.materia),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _colorForMateria(b.materia.id),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(6),
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
                              if (b.materia.profesor.isNotEmpty)
                                Text(
                                  'Prof. ${b.materia.profesor}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                  ),
                                ),
                              if (b.materia.salon.isNotEmpty ||
                                  b.materia.edificio.isNotEmpty)
                                Text(
                                  [
                                    if (b.materia.salon.isNotEmpty)
                                      'Salón ${b.materia.salon}',
                                    if (b.materia.edificio.isNotEmpty)
                                      'Edif. ${b.materia.edificio}',
                                  ].join('\n'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
}

/// Pequeña clase interna para facilitar el cálculo de bloques por día.
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
