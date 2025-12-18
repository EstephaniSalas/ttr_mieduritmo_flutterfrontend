// lib/screens/calendario_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/usuario.dart';
import '../models/evento.dart';
import '../services/usuario_api_service.dart';
import '../services/calendario_sep_api_service.dart';
import '../services/eventos_api_service.dart';
import '../theme/app_colors.dart';
import 'home_shell_screen.dart';

import '../services/notification_service.dart';
import '../widgets/main_app_bar.dart';

class CalendarioScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api;

  const CalendarioScreen({
    super.key,
    required this.usuario,
    required this.api,
  });

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  late final CalendarioSepApiService _calendarioService;
  late final EventosApiService _eventosService;
  late final NotificationService _notificationService;

  late Usuario _usuario;

  final _formKeyEvento = GlobalKey<FormState>();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _cargando = false;
  String? _error;

  // fecha normalizada -> lista de eventos SEP
  final Map<DateTime, List<EventoCalendarioSep>> _eventosPorDia = {};

  // fecha normalizada -> lista de eventos personales
  final Map<DateTime, List<EventoPersonal>> _eventosPersonalesPorDia = {};

  @override
  void initState() {
    super.initState();
    _calendarioService = CalendarioSepApiService(widget.api.dio);
    _eventosService = EventosApiService(widget.api.dio);
    _notificationService = NotificationService();

    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    _usuario = widget.usuario;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEventosMes(_focusedDay);
      _cargarEventosPersonales();
    });
  }

  DateTime _normalizar(DateTime d) => DateTime(d.year, d.month, d.day);

  List<EventoCalendarioSep> _eventosDe(DateTime day) {
    return _eventosPorDia[_normalizar(day)] ?? const [];
  }

  List<EventoPersonal> _eventosPersonalesDe(DateTime day) {
    return _eventosPersonalesPorDia[_normalizar(day)] ?? const [];
  }

  String _formatTimeOfDay24(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<TimeOfDay?> _showCustomTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    int hour = initialTime.hour % 12;
    if (hour == 0) hour = 12;

    int minute = initialTime.minute; // <- sin redondeo
    bool isAm = initialTime.hour < 12;

    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar hora', textAlign: TextAlign.center),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_drop_up),
                                onPressed: () {
                                  setState(() {
                                    hour = hour == 12 ? 1 : hour + 1;
                                  });
                                },
                              ),
                              Container(
                                width: 70,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  hour.toString().padLeft(2, '0'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_drop_down),
                                onPressed: () {
                                  setState(() {
                                    hour = hour == 1 ? 12 : hour - 1;
                                  });
                                },
                              ),
                              const SizedBox(height: 4),
                              const Text('Hora',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(':',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_drop_up),
                                onPressed: () {
                                  setState(() {
                                    minute = minute == 59 ? 0 : minute + 1;
                                  });
                                },
                              ),
                              Container(
                                width: 70,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  minute.toString().padLeft(2, '0'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_drop_down),
                                onPressed: () {
                                  setState(() {
                                    minute = minute == 0 ? 59 : minute - 1;
                                  });
                                },
                              ),
                              const SizedBox(height: 4),
                              const Text('Min',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => isAm = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              decoration: BoxDecoration(
                                color: isAm ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'AM',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isAm ? Colors.white : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => setState(() => isAm = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              decoration: BoxDecoration(
                                color: !isAm ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PM',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      !isAm ? Colors.white : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                int hour24 = hour;
                if (hour == 12) {
                  hour24 = isAm ? 0 : 12;
                } else {
                  hour24 = isAm ? hour : hour + 12;
                }

                final selectedTime = TimeOfDay(hour: hour24, minute: minute);
                Navigator.pop(dialogContext, selectedTime);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _cargarEventosMes(DateTime referencia) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final firstDayOfMonth = DateTime(referencia.year, referencia.month, 1);
      final lastDayOfMonth = DateTime(referencia.year, referencia.month + 1, 0);

      final desde = firstDayOfMonth.subtract(const Duration(days: 7));
      final hasta = lastDayOfMonth.add(const Duration(days: 7));

      final eventos = await _calendarioService.obtenerEventosRango(
        desde: desde,
        hasta: hasta,
        ciclo: "2025-2026",
      );

      final mapa = <DateTime, List<EventoCalendarioSep>>{};
      for (final ev in eventos) {
        final key = _normalizar(ev.fecha);
        mapa.putIfAbsent(key, () => []).add(ev);
      }

      if (!mounted) return;
      setState(() {
        _eventosPorDia
          ..clear()
          ..addAll(mapa);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _cargarEventosPersonales() async {
    try {
      final idUsuario =
          widget.usuario.uid; // ajusta si tu modelo usa otro campo
      final eventos = await _eventosService.obtenerEventosUsuario(idUsuario);

      final mapa = <DateTime, List<EventoPersonal>>{};
      for (final ev in eventos) {
        final key = _normalizar(ev.fechaEvento);
        mapa.putIfAbsent(key, () => []).add(ev);
      }

      if (!mounted) return;
      setState(() {
        _eventosPersonalesPorDia
          ..clear()
          ..addAll(mapa);
      });
    } catch (e) {
      // silencioso por ahora
    }
  }

  Future<void> _abrirBottomSheetEvento({EventoPersonal? evento}) async {
    final bool editando = evento != null;

    // Controllers
    final tituloCtrl =
        TextEditingController(text: editando ? evento!.tituloEvento : '');
    final descCtrl =
        TextEditingController(text: editando ? evento!.descripcionEvento : '');
    final horaInicioCtrl =
        TextEditingController(text: editando ? evento!.horaInicio : '');
    final horaFinCtrl =
        TextEditingController(text: editando ? evento!.horaFin : '');

    DateTime fecha = editando ? evento!.fechaEvento : _selectedDay;
    String horaInicio = horaInicioCtrl.text;
    String horaFin = horaFinCtrl.text;
    bool importante = editando ? evento!.importante : false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return GestureDetector(
              onTap: () => FocusScope.of(ctx).unfocus(),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Form(
                      key: _formKeyEvento,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                editando
                                    ? 'Modificar evento'
                                    : 'Agregar evento',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Fecha: ${fecha.day.toString().padLeft(2, '0')}-'
                              '${fecha.month.toString().padLeft(2, '0')}-'
                              '${fecha.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: tituloCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Título del evento *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'El título es obligatorio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: horaInicioCtrl,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Hora inicio *',
                                    hintText: 'HH:MM',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Obligatorio';
                                    }
                                    return null;
                                  },
                                  onTap: () async {
                                    final initial = horaInicio.isNotEmpty
                                        ? _parseTime(horaInicio)
                                        : const TimeOfDay(hour: 8, minute: 0);

                                    final picked = await _showCustomTimePicker(
                                      context: ctx,
                                      initialTime: initial,
                                    );

                                    if (picked != null) {
                                      final value = _formatTimeOfDay24(picked);
                                      setModalState(() {
                                        horaInicio = value;
                                        horaInicioCtrl.text = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: horaFinCtrl,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Hora fin *',
                                    hintText: 'HH:MM',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Obligatorio';
                                    }
                                    return null;
                                  },
                                  onTap: () async {
                                    final initial = horaFin.isNotEmpty
                                        ? _parseTime(horaFin)
                                        : const TimeOfDay(hour: 9, minute: 0);

                                    final picked = await _showCustomTimePicker(
                                      context: ctx,
                                      initialTime: initial,
                                    );

                                    if (picked != null) {
                                      final value = _formatTimeOfDay24(picked);
                                      setModalState(() {
                                        horaFin = value;
                                        horaFinCtrl.text = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Importante',
                                style: TextStyle(fontSize: 13),
                              ),
                              const Spacer(),
                              Switch(
                                value: importante,
                                activeColor: AppColors.black,
                                onChanged: (v) {
                                  setModalState(() {
                                    importante = v;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (editando)
                                TextButton.icon(
                                  onPressed: () async {
                                    final confirmar = await showDialog<bool>(
                                      context: ctx,
                                      builder: (dCtx) => AlertDialog(
                                        title: const Text('Eliminar evento'),
                                        content: const Text(
                                            '¿Quieres eliminar este evento personal?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dCtx, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dCtx, true),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmar != true) return;

                                    final idUsuario = widget.usuario.uid;
                                    try {
                                      // 🔔 Cancelar notificaciones
                                      await _notificationService
                                          .cancelarNotificacionesEvento(
                                              evento!.uid);

                                      await _eventosService.borrarEvento(
                                        idUsuario: idUsuario,
                                        idEvento: evento.uid,
                                      );

                                      if (mounted) {
                                        setState(() {
                                          final key =
                                              _normalizar(evento.fechaEvento);
                                          _eventosPersonalesPorDia[key]
                                              ?.removeWhere(
                                                  (e) => e.uid == evento.uid);
                                          if ((_eventosPersonalesPorDia[key]
                                                  ?.isEmpty ??
                                              false)) {
                                            _eventosPersonalesPorDia
                                                .remove(key);
                                          }
                                        });
                                      }

                                      Navigator.pop(ctx);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Evento y notificaciones eliminados ✅'),
                                            backgroundColor: AppColors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      Navigator.pop(ctx);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error al eliminar el evento: $e'),
                                            backgroundColor: AppColors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  label: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              if (editando) const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () async {
                                    // Valida formulario
                                    if (!_formKeyEvento.currentState!
                                        .validate()) {
                                      return;
                                    }

                                    final titulo = tituloCtrl.text.trim();
                                    final descripcion = descCtrl.text.trim();
                                    final idUsuario = widget.usuario.uid;

                                    try {
                                      if (editando) {
                                        final actualizado =
                                            await _eventosService
                                                .actualizarEvento(
                                          idUsuario: idUsuario,
                                          idEvento: evento!.uid,
                                          titulo: titulo,
                                          descripcion: descripcion,
                                          fecha: fecha,
                                          horaInicio:
                                              horaInicioCtrl.text.trim(),
                                          horaFin: horaFinCtrl.text.trim(),
                                          importante: importante,
                                        );

                                        final horaInicioParts = horaInicioCtrl
                                            .text
                                            .trim()
                                            .split(':');
                                        final fechaHoraInicio = DateTime(
                                          fecha.year,
                                          fecha.month,
                                          fecha.day,
                                          int.parse(horaInicioParts[0]),
                                          int.parse(horaInicioParts[1]),
                                        );

                                        await _notificationService
                                            .programarNotificacionesEvento(
                                          eventoId: actualizado.uid,
                                          titulo: actualizado.tituloEvento,
                                          descripcion:
                                              actualizado.descripcionEvento,
                                          fechaHoraInicio: fechaHoraInicio,
                                          importante: actualizado.importante,
                                        );

                                        if (mounted) {
                                          setState(() {
                                            final oldKey =
                                                _normalizar(evento.fechaEvento);
                                            final newKey = _normalizar(
                                                actualizado.fechaEvento);

                                            _eventosPersonalesPorDia[oldKey]
                                                ?.removeWhere(
                                                    (e) => e.uid == evento.uid);
                                            if ((_eventosPersonalesPorDia[
                                                        oldKey]
                                                    ?.isEmpty ??
                                                false)) {
                                              _eventosPersonalesPorDia
                                                  .remove(oldKey);
                                            }

                                            _eventosPersonalesPorDia
                                                .putIfAbsent(newKey, () => [])
                                                .add(actualizado);
                                          });
                                        }

                                        Navigator.pop(ctx);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Evento actualizado con notificaciones ✅'),
                                              backgroundColor: AppColors.black,
                                            ),
                                          );
                                        }

                                        if (mounted) {
                                          setState(() {
                                            final oldKey =
                                                _normalizar(evento.fechaEvento);
                                            final newKey = _normalizar(
                                                actualizado.fechaEvento);

                                            _eventosPersonalesPorDia[oldKey]
                                                ?.removeWhere(
                                                    (e) => e.uid == evento.uid);
                                            if ((_eventosPersonalesPorDia[
                                                        oldKey]
                                                    ?.isEmpty ??
                                                false)) {
                                              _eventosPersonalesPorDia
                                                  .remove(oldKey);
                                            }

                                            _eventosPersonalesPorDia
                                                .putIfAbsent(newKey, () => [])
                                                .add(actualizado);
                                          });
                                        }

                                        Navigator.pop(ctx);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Evento actualizado correctamente.'),
                                              backgroundColor: AppColors.black,
                                            ),
                                          );
                                        }
                                      } else {
                                        final nuevo =
                                            await _eventosService.crearEvento(
                                          idUsuario: idUsuario,
                                          titulo: titulo,
                                          descripcion: descripcion,
                                          fecha: fecha,
                                          horaInicio:
                                              horaInicioCtrl.text.trim(),
                                          horaFin: horaFinCtrl.text.trim(),
                                          importante: importante,
                                        );

                                        final horaInicioParts = horaInicioCtrl
                                            .text
                                            .trim()
                                            .split(':');
                                        final fechaHoraInicio = DateTime(
                                          fecha.year,
                                          fecha.month,
                                          fecha.day,
                                          int.parse(horaInicioParts[0]),
                                          int.parse(horaInicioParts[1]),
                                        );

                                        await _notificationService
                                            .programarNotificacionesEvento(
                                          eventoId: nuevo.uid,
                                          titulo: nuevo.tituloEvento,
                                          descripcion: nuevo.descripcionEvento,
                                          fechaHoraInicio: fechaHoraInicio,
                                          importante: nuevo.importante,
                                        );

                                        if (mounted) {
                                          setState(() {
                                            final key =
                                                _normalizar(nuevo.fechaEvento);
                                            _eventosPersonalesPorDia
                                                .putIfAbsent(key, () => [])
                                                .add(nuevo);
                                          });
                                        }

                                        Navigator.pop(ctx);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Evento creado con notificaciones ✅'),
                                              backgroundColor: AppColors.black,
                                            ),
                                          );
                                        }

                                        if (mounted) {
                                          setState(() {
                                            final key =
                                                _normalizar(nuevo.fechaEvento);
                                            _eventosPersonalesPorDia
                                                .putIfAbsent(key, () => [])
                                                .add(nuevo);
                                          });
                                        }

                                        Navigator.pop(ctx);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Evento creado correctamente.'),
                                              backgroundColor: AppColors.black,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      Navigator.pop(ctx);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error al guardar el evento: $e'),
                                            backgroundColor: AppColors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    editando
                                        ? 'Guardar cambios'
                                        : 'Agregar evento',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: MainAppBar(
        usuario: _usuario,
        api: widget.api,
        subtitle: "Asi se ve tu mes",
        onUsuarioActualizado: (nuevoUsuario) {
          setState(() {
            _usuario = nuevoUsuario;
          });
        },
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildModeToggle(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Calendario",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar eventos personales'),
                        content: const Text(
                            'Se eliminarán todos tus eventos personales. ¿Quieres continuar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );

                    if (confirmar != true) return;

                    try {
                      final idUsuario = widget.usuario.uid;

                      // 🔔 Cancelar notificaciones de todos los eventos
                      for (var eventos in _eventosPersonalesPorDia.values) {
                        for (var evento in eventos) {
                          await _notificationService
                              .cancelarNotificacionesEvento(evento.uid);
                        }
                      }

                      await _eventosService
                          .borrarTodosEventosUsuario(idUsuario);

                      if (!mounted) return;
                      setState(() {
                        _eventosPersonalesPorDia.clear();
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Eventos y notificaciones eliminados ✅'),
                          backgroundColor: AppColors.red,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      if (e is DioException && e.response?.statusCode == 404) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'No había eventos personales para eliminar.'),
                            backgroundColor: AppColors.black,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Error al eliminar eventos personales: $e'),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                InkWell(
                  onTap: () {
                    _abrirBottomSheetEvento();
                  },
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
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Toggle superior Horario / Calendario -------------------------

  Widget _buildModeToggle() {
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
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeShellScreen(
                          usuario: widget.usuario,
                          api: widget.api,
                          initialIndex: 1,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        "Horario escolar",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Calendario",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  // Contenido principal ------------------------------------------

  Widget _buildContent() {
    if (_cargando && _eventosPorDia.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildCalendarCard(),
          const SizedBox(height: 16),
          _buildEventosDelDiaCard(),
          const SizedBox(height: 16),
          _buildEventosPersonalesDelDiaCard(),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            TableCalendar<EventoCalendarioSep>(
              locale: 'es_MX',
              focusedDay: _focusedDay,
              firstDay: DateTime(2025, 8, 1),
              lastDay: DateTime(2026, 8, 31),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              availableGestures: AvailableGestures.horizontalSwipe,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                _focusedDay = focused;
                _cargarEventosMes(focused);
              },
              eventLoader: _eventosDe,
              calendarStyle: const CalendarStyle(
                // dejamos que los builders manejen today/selected,
                // solo configuramos los marcadores.
                markerSize: 6,
                markersAlignment: Alignment.bottomCenter,
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders(
                // Día normal
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day);
                },
                // Día seleccionado
                selectedBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day, isSelected: true);
                },
                // Hoy
                todayBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day, isToday: true);
                },
                // Marcadores para eventos oficiales SEP (vacaciones/festivos)
                markerBuilder: (context, date, eventos) {
                  if (eventos.isEmpty) return const SizedBox.shrink();

                  bool hayVacaciones = false;
                  bool hayFestivo = false;

                  for (final ev in eventos) {
                    switch (ev.tipo) {
                      case "VACACIONES":
                        hayVacaciones = true;
                        break;
                      case "DIA_FESTIVO":
                        hayFestivo = true;
                        break;
                    }
                  }

                  final dots = <Widget>[];
                  if (hayVacaciones) {
                    dots.add(_buildMarkerDot(AppColors.blue));
                  }
                  if (hayFestivo) {
                    dots.add(_buildMarkerDot(AppColors.red));
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: dots,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendItem(color: AppColors.blue, text: "Vacaciones"),
                SizedBox(width: 16),
                _LegendItem(
                  color: AppColors.red,
                  text: "Suspensión de clases / Día festivo",
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ));
  }

  Widget _buildEventosDelDiaCard() {
    final eventosHoy = _eventosDe(_selectedDay);
    final fechaTexto =
        "${_selectedDay.day.toString().padLeft(2, '0')}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.year}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Eventos del día $fechaTexto",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (eventosHoy.isEmpty)
            const Text(
              "No hay eventos oficiales en este día.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            )
          else
            Column(
              children: eventosHoy.map(_buildEventoItem).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEventosPersonalesDelDiaCard() {
    final eventosPersonales = _eventosPersonalesDe(_selectedDay);
    final fechaTexto =
        "${_selectedDay.day.toString().padLeft(2, '0')}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.year}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Eventos personales del día $fechaTexto",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (eventosPersonales.isEmpty)
            const Text(
              "No tienes eventos personales registrados en este día.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            )
          else
            Column(
              children:
                  eventosPersonales.map(_buildEventoPersonalItem).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEventoItem(EventoCalendarioSep ev) {
    Color color;
    String tituloTipo;
    switch (ev.tipo) {
      case "VACACIONES":
        color = AppColors.blue;
        tituloTipo = "Vacaciones";
        break;
      case "DIA_FESTIVO":
        color = AppColors.red;
        tituloTipo = "Día festivo";
        break;
      default:
        color = Colors.black87;
        tituloTipo = ev.tipo;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloTipo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ev.descripcion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  ev.esHabil ? "Día laboral" : "Día no laboral",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoPersonalItem(EventoPersonal ev) {
    final color = ev.importante ? AppColors.red : AppColors.black;

    return InkWell(
      onTap: () => _abrirBottomSheetEvento(evento: ev),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 40,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ev.tituloEvento,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (ev.descripcionEvento.trim().isNotEmpty)
                    Text(
                      ev.descripcionEvento,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  Text(
                    "${ev.horaInicio} - ${ev.horaFin}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDayCell(DateTime day,
      {bool isToday = false, bool isSelected = false}) {
    final tienePersonales = _eventosPersonalesDe(day).isNotEmpty;

    Color textColor = Colors.black87;
    Color fillColor = Colors.transparent;
    Border? border;

    if (isSelected) {
      fillColor = AppColors.black;
      textColor = Colors.white;
    } else if (isToday) {
      fillColor = AppColors.blue;
      textColor = Colors.white;
    } else {
      fillColor = Colors.transparent;
      textColor = Colors.black87;
    }

    // Si hay eventos personales y no es hoy ni seleccionado,
    // dibujamos un círculo con borde negro.
    if (tienePersonales && !isSelected && !isToday) {
      border = Border.all(color: Colors.black87, width: 1.4);
    }

    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: fillColor,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  // Barra inferior de navegación --------------------------------

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == 1) {
          return;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeShellScreen(
              usuario: widget.usuario,
              api: widget.api,
              initialIndex: index,
            ),
          ),
          (route) => false,
        );
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Horario',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.task),
          label: 'Tareas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notes),
          label: 'Notas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book),
          label: 'Estudio',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
