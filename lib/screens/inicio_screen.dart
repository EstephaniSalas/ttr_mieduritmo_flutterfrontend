// lib/screens/inicio_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_api_service.dart';
import '../widgets/main_app_bar.dart';

class DashboardData {
  final String? claseActual;
  final String? siguienteClase;
  final int totalClasesHoy;

  final int totalTareasPendientes;
  final int tareasHoy;
  final int tareasProximosDias; // 1..7 días

  final int eventosProximos7;
  final Map<String, int> puntosSaturacion; // por día de la semana
  final Map<String, dynamic>? proximoEvento;

  DashboardData({
    required this.claseActual,
    required this.siguienteClase,
    required this.totalClasesHoy,
    required this.totalTareasPendientes,
    required this.tareasHoy,
    required this.tareasProximosDias,
    required this.eventosProximos7,
    required this.puntosSaturacion,
    required this.proximoEvento,
  });
}

class InicioScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api;

  const InicioScreen({
    super.key,
    required this.usuario,
    required this.api,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Usuario _usuario;

  bool _loading = true;
  String? _error;
  DashboardData? _data;

  static const List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  // Acento visual (puedes moverlo a AppColors si quieres)
  static const Color _accent = Color.fromARGB(255, 2, 0, 7);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _usuario = widget.usuario;
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) Materias
      final respMaterias = await widget.api.dio.get(
        '/materias/idUsuario/${widget.usuario.uid}',
      );
      final materias =
          List<Map<String, dynamic>>.from(respMaterias.data['materias'] ?? []);

      // 2) Tareas
      final respTareas = await widget.api.dio.get(
        '/tareas/idUsuario/${widget.usuario.uid}',
      );
      final tareas =
          List<Map<String, dynamic>>.from(respTareas.data['tareas'] ?? []);

      // 3) Eventos
      final respEventos = await widget.api.dio.get(
        '/eventos/idUsuario/${widget.usuario.uid}',
      );
      final eventos =
          List<Map<String, dynamic>>.from(respEventos.data['eventos'] ?? []);

      final data = _buildDashboardData(
        materias: materias,
        tareas: tareas,
        eventos: eventos,
      );

      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar el dashboard: $e';
        _loading = false;
      });
    }
  }

  DashboardData _buildDashboardData({
  required List<Map<String, dynamic>> materias,
  required List<Map<String, dynamic>> tareas,
  required List<Map<String, dynamic>> eventos,
}) {
  final now = DateTime.now();
  final hoySinHora = DateTime(now.year, now.month, now.day);
  final diaHoyNombre = _nombreDia(now.weekday);

  // ---------- CLASES HOY: actual, siguiente, total ----------
  final bloquesHoy = <_BloqueClase>[];
  int totalClasesHoy = 0;

  for (final m in materias) {
    final nombreMateria = (m['nombreMateria'] ?? '').toString();
    final List<dynamic> horarios =
    (m['horariosMateria'] ?? m['horarios'] ?? []) as List<dynamic>;

    for (final h in horarios) {
      if (h is! Map<String, dynamic>) continue;
      if (h['dia'] != diaHoyNombre) continue;

      // Siempre contamos la clase para "total del día"
      totalClasesHoy++;

      // Intentamos parsear horas para actual/siguiente; si falla, igual ya
      // quedó sumada al total.
      final inicio = _parseHoraHoy(h['horaInicio']);
      final fin = _parseHoraHoy(h['horaFin']);
      if (inicio == null || fin == null) continue;

      bloquesHoy.add(
        _BloqueClase(materia: nombreMateria, inicio: inicio, fin: fin),
      );
    }
  }

  bloquesHoy.sort((a, b) => a.inicio.compareTo(b.inicio));

  String? claseActual;
  String? siguienteClase;

  for (final b in bloquesHoy) {
    if (now.isAfter(b.inicio) && now.isBefore(b.fin)) {
      claseActual = b.materia;
    } else if (b.inicio.isAfter(now)) {
      siguienteClase ??= b.materia;
    }
  }

  // ---------- TAREAS: totales, hoy, próximos días ----------
  int totalPendientes = 0;
  int tareasHoy = 0;
  int tareasProximosDias = 0;

  for (final t in tareas) {
    final estatus = (t['estatusTarea'] ?? '').toString().toLowerCase();
    if (estatus == 'completada') continue;

    totalPendientes++;

    final fechaStr = t['fechaEntregaTarea']?.toString();
    if (fechaStr == null) continue;

    DateTime? fecha;
    try {
      fecha = DateTime.parse(fechaStr);
    } catch (_) {
      continue;
    }

    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final diff = fechaSinHora.difference(hoySinHora).inDays;

    if (diff == 0) {
      tareasHoy++;
    } else if (diff >= 1 && diff <= 7) {
      tareasProximosDias++;
    }
  }

  // ---------- Eventos: próximo y conteo próximos 7 días ----------
  Map<String, dynamic>? proximoEvento;
  DateTime? fechaProx;
  int eventosProximos7 = 0;

  for (final e in eventos) {
    final fechaStr = e['fechaEvento']?.toString();
    if (fechaStr == null) continue;
    DateTime? fecha;
    try {
      fecha = DateTime.parse(fechaStr);
    } catch (_) {
      continue;
    }

    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final diff = fechaSinHora.difference(hoySinHora).inDays;

    if (diff >= 0 && diff <= 7) {
      eventosProximos7++;
      if (fechaProx == null || fechaSinHora.isBefore(fechaProx)) {
        fechaProx = fechaSinHora;
        proximoEvento = e;
      }
    }
  }

  // ---------- Saturación semanal ----------
  final Map<String, int> puntosPorDia = {
    for (final d in _diasSemana) d: 0,
  };

  final mondayThisWeek =
      hoySinHora.subtract(Duration(days: hoySinHora.weekday - DateTime.monday));

  final Map<String, DateTime> fechaPorDia = {};
  for (int i = 0; i < 7; i++) {
    final f = mondayThisWeek.add(Duration(days: i));
    fechaPorDia[_nombreDia(f.weekday)] = DateTime(f.year, f.month, f.day);
  }

  // Materias -> 1 punto por horario de ese día
  for (final m in materias) {
    final List<dynamic> horarios = 
    (m['horariosMateria'] ?? m['horarios'] ?? []) as List<dynamic>;
    for (final h in horarios) {
      if (h is! Map<String, dynamic>) continue;
      final dia = h['dia']?.toString();
      if (dia == null || !puntosPorDia.containsKey(dia)) continue;
      puntosPorDia[dia] = puntosPorDia[dia]! + 1;
    }
  }

  // Eventos de la semana -> +1 si hay al menos uno en ese día
  final Set<String> diasConEvento = {};
  for (final e in eventos) {
    final fechaStr = e['fechaEvento']?.toString();
    if (fechaStr == null) continue;
    DateTime? f;
    try {
      f = DateTime.parse(fechaStr);
    } catch (_) {
      continue;
    }
    final fSinHora = DateTime(f.year, f.month, f.day);
    if (fSinHora.isBefore(mondayThisWeek) ||
        fSinHora.isAfter(mondayThisWeek.add(const Duration(days: 6)))) {
      continue;
    }
    final diaNombre = _nombreDia(fSinHora.weekday);
    diasConEvento.add(diaNombre);
  }
  for (final d in diasConEvento) {
    if (puntosPorDia.containsKey(d)) {
      puntosPorDia[d] = puntosPorDia[d]! + 1;
    }
  }

  return DashboardData(
    claseActual: claseActual,
    siguienteClase: siguienteClase,
    totalClasesHoy: totalClasesHoy,
    totalTareasPendientes: totalPendientes,
    tareasHoy: tareasHoy,
    tareasProximosDias: tareasProximosDias,
    eventosProximos7: eventosProximos7,
    puntosSaturacion: puntosPorDia,
    proximoEvento: proximoEvento,
  );
}


  String _nombreDia(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miercoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return 'Lunes';
    }
  }

  DateTime? _parseHoraHoy(dynamic valor) {
  if (valor == null) return null;
  final s = valor.toString().trim();
  if (s.isEmpty) return null;

  final now = DateTime.now();

  // Separar en HH:MM(:SS opcional)
  final partes = s.split(':');
  if (partes.length < 2) return null;

  // Hora (puede venir con espacios, pero sin AM/PM normalmente)
  var horaStr = partes[0].trim();
  int? h = int.tryParse(horaStr);
  if (h == null) return null;

  // Minutos: tomar los primeros dos dígitos que aparezcan
  final minMatch = RegExp(r'\d{1,2}').firstMatch(partes[1]);
  if (minMatch == null) return null;
  int m = int.parse(minMatch.group(0)!);

  // Detectar AM/PM en el string completo
  final lower = s.toLowerCase();
  final tieneAm = lower.contains('am');
  final tienePm = lower.contains('pm');

  if (tienePm && h < 12) h += 12;
  if (tieneAm && h == 12) h = 0;

  return DateTime(now.year, now.month, now.day, h, m);
}


  String _formatearFechaCorta(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: MainAppBar(
        usuario: _usuario,
        api: widget.api,
        subtitle: "Bienvenido",
        onUsuarioActualizado: (nuevoUsuario) {
          setState(() {
            _usuario = nuevoUsuario;
          });
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    children: [
                      _buildResumenRapido(data!),
                      const SizedBox(height: 16),
                      _DashboardCard(
                        title: 'Clases de hoy',
                        icon: Icons.school,
                        accent: _accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(
                              'Total de clases hoy',
                              data.totalClasesHoy.toString(),
                            ),
                            const SizedBox(height: 8),
                            _infoRow(
                              'Actual',
                              data.claseActual ?? 'Sin clase en este momento',
                            ),
                            const SizedBox(height: 4),
                            _infoRow(
                              'Siguiente',
                              data.siguienteClase ?? 'No hay más clases hoy',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DashboardCard(
                        title: 'Tareas',
                        icon: Icons.checklist,
                        accent: _accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(
                              'Pendientes totales',
                              data.totalTareasPendientes.toString(),
                            ),
                            const SizedBox(height: 8),
                            _infoRow(
                              'Para hoy',
                              data.tareasHoy.toString(),
                            ),
                            const SizedBox(height: 4),
                            _infoRow(
                              'Próximos días (1-7)',
                              data.tareasProximosDias.toString(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DashboardCard(
                        title: 'Próximo evento',
                        icon: Icons.event,
                        accent: _accent,
                        child: _buildProximoEvento(data.proximoEvento),
                      ),
                      const SizedBox(height: 12),
                      _DashboardCard(
                        title: 'Saturación de la semana',
                        icon: Icons.bar_chart,
                        accent: _accent,
                        child: _buildSaturacionSemana(data.puntosSaturacion),
                      ),
                    ],
                  ),
                ),
    );
  }

  // -------- Widgets de UI --------

  Widget _buildResumenRapido(DashboardData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 132, 132, 132),
            Color.fromARGB(255, 132, 132, 132)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.dashboard, color: Color.fromARGB(221, 3, 3, 3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen rápido',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color.fromARGB(221, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipResumen(
                      icon: Icons.school,
                      label: 'Clases hoy',
                      value: data.totalClasesHoy.toString(),
                    ),
                    _chipResumen(
                      icon: Icons.check_circle_outline,
                      label: 'Tareas pendientes',
                      value: data.totalTareasPendientes.toString(),
                    ),
                    _chipResumen(
                      icon: Icons.event_available,
                      label: 'Eventos',
                      value: data.eventosProximos7.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipResumen({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProximoEvento(Map<String, dynamic>? e) {
    if (e == null) {
      return const Text(
        'No tienes eventos próximos en los próximos 7 días.',
        style: TextStyle(fontSize: 13),
      );
    }

    DateTime? fecha;
    final fechaStr = e['fechaEvento']?.toString();
    if (fechaStr != null) {
      try {
        fecha = DateTime.parse(fechaStr);
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e['tituloEvento']?.toString() ?? 'Evento sin título',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        if (fecha != null)
          Text(
            'Fecha: ${_formatearFechaCorta(fecha)}',
            style: const TextStyle(fontSize: 13),
          ),
        if (e['descripcionEvento'] != null &&
            e['descripcionEvento'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            e['descripcionEvento'].toString(),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ],
    );
  }

  Widget _buildSaturacionSemana(Map<String, int> puntos) {
  final maxPuntos =
      puntos.values.fold<int>(0, (prev, e) => max(prev, e));
  if (maxPuntos == 0) {
    return const Text(
      'Aún no tienes horarios ni eventos registrados esta semana.',
      style: TextStyle(fontSize: 13),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Leyenda: 1 punto = 1 materia con horario ese día '
        '+ 1 punto extra si hay al menos un evento registrado ese día.',
        style: TextStyle(
          fontSize: 11,
          color: Colors.black54,
        ),
      ),
      const SizedBox(height: 8),
      ..._diasSemana.map((dia) {
        final puntosDia = puntos[dia] ?? 0;
        final ratio =
            maxPuntos == 0 ? 0.0 : (puntosDia / maxPuntos).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  dia,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E4E8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$puntosDia pt${puntosDia == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
    ],
  );
}

}

class _BloqueClase {
  final String materia;
  final DateTime inicio;
  final DateTime fin;

  _BloqueClase({
    required this.materia,
    required this.inicio,
    required this.fin,
  });
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData icon;
  final Color accent;

  const _DashboardCard({
    required this.title,
    required this.child,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
