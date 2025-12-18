// lib/screens/add_tarea_sheet.dart
import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../models/tarea.dart';
import '../theme/app_colors.dart';

class AddTareaPayload {
  final String? id; // null = crear, no null = editar
  final String nombreTarea;
  final String? materiaId;
  final String descripcionTarea;
  final String tipoTarea; // Tarea / Proyecto / Examen
  final DateTime fechaEntrega;
  final String horaEntrega24; // HH:MM

  AddTareaPayload({
    this.id,
    required this.nombreTarea,
    required this.materiaId,
    required this.descripcionTarea,
    required this.tipoTarea,
    required this.fechaEntrega,
    required this.horaEntrega24,
  });
}

class AddTareaSheet extends StatefulWidget {
  final Future<Tarea> Function(AddTareaPayload payload) onSubmit;
  final Future<void> Function()? onDelete;
  final Tarea? tareaInicial;
  final List<Materia> materias;

  const AddTareaSheet({
    super.key,
    required this.onSubmit,
    this.onDelete,
    this.tareaInicial,
    this.materias = const [],
  });

  @override
  State<AddTareaSheet> createState() => _AddTareaSheetState();
}

class _AddTareaSheetState extends State<AddTareaSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  String _tipoSeleccionado = 'Tarea';
  Materia? _materiaSeleccionada;
  DateTime? _fechaEntrega;
  TimeOfDay? _horaEntrega;

  bool _submitting = false;
  String? _submitError;

  bool get _esEdicion => widget.tareaInicial != null;

  @override
  void initState() {
    super.initState();

    if (widget.tareaInicial != null) {
      final t = widget.tareaInicial!;
      _nombreCtrl.text = t.nombreTarea;
      _descripcionCtrl.text = t.descripcionTarea;
      _tipoSeleccionado = t.tipoTarea;
      _fechaEntrega = t.fechaEntregaTarea;

      if (t.materiaId != null) {
        _materiaSeleccionada =
            _buscarMateriaPorId(widget.materias, t.materiaId!);
      } else if (t.materiaNombre != null) {
        _materiaSeleccionada =
            _buscarMateriaPorNombre(widget.materias, t.materiaNombre!);
      }

      _horaEntrega = _parseHora(t.horaEntregaTarea);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Materia? _buscarMateriaPorId(List<Materia> materias, String id) {
    try {
      return materias.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Materia? _buscarMateriaPorNombre(List<Materia> materias, String nombre) {
    try {
      return materias.firstWhere((m) => m.nombre == nombre);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseHora(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  String _formatearHora(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final initial = _fechaEntrega ?? hoy;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 5),
    );

    if (picked == null) return;

    setState(() {
      _fechaEntrega = picked;
    });
  }

  Future<void> _seleccionarHora() async {
    final initial = _horaEntrega ?? const TimeOfDay(hour: 12, minute: 0);

    final selectedTime = await _showCustomTimePicker(
      initialTime: initial,
    );

    if (selectedTime == null) return;

    setState(() {
      _horaEntrega = selectedTime;
    });
  }

  // ✅ MINUTOS 1 EN 1 (0..59). OJO: elimina cualquier redondeo tipo: minute = (minute ~/ 5) * 5;
Future<TimeOfDay?> _showCustomTimePicker({
  required TimeOfDay initialTime,
}) async {
  int hour = initialTime.hour % 12;
  if (hour == 0) hour = 12;

  int minute = initialTime.minute; // <- SIN redondeo
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
                        // Hora
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
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
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
                            const Text(
                              'Hora',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Minutos (1 en 1)
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
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
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
                            const Text(
                              'Min',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                              vertical: 12,
                              horizontal: 24,
                            ),
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
                              vertical: 12,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: !isAm ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: !isAm ? Colors.white : Colors.grey[700],
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

              Navigator.pop(
                dialogContext,
                TimeOfDay(hour: hour24, minute: minute),
              );
            },
            child: const Text('Aceptar'),
          ),
        ],
      );
    },
  );

  return result;
}


  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaEntrega == null || _horaEntrega == null) {
      setState(() {
        _submitError = 'Selecciona fecha y hora de entrega';
      });
      return;
    }

    final payload = AddTareaPayload(
      id: widget.tareaInicial?.id,
      nombreTarea: _nombreCtrl.text.trim(),
      materiaId: _materiaSeleccionada?.id,
      descripcionTarea: _descripcionCtrl.text.trim(),
      tipoTarea: _tipoSeleccionado,
      fechaEntrega: _fechaEntrega!,
      horaEntrega24: _formatearHora(_horaEntrega!),
    );

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final tarea = await widget.onSubmit(payload);
      if (mounted) Navigator.of(context).pop(tarea);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _esEdicion ? 'Editar tarea' : 'Agregar tarea';

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.95,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tipo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F2F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _tipoSeleccionado,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Tarea',
                                  child: Text('Tarea'),
                                ),
                                DropdownMenuItem(
                                  value: 'Proyecto',
                                  child: Text('Proyecto'),
                                ),
                                DropdownMenuItem(
                                  value: 'Examen',
                                  child: Text('Examen'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _tipoSeleccionado = v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Materia (opcional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F2F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Materia>(
                              value: _materiaSeleccionada,
                              hint: const Text('Selecciona materia'),
                              isExpanded: true,
                              items: widget.materias
                                  .map(
                                    (m) => DropdownMenuItem<Materia>(
                                      value: m,
                                      child: Text(m.nombre),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (m) =>
                                  setState(() => _materiaSeleccionada = m),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _nombreCtrl,
                          hint: 'Título de la tarea / proyecto / examen',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _descripcionCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Descripción (opcional)',
                            filled: true,
                            fillColor: const Color(0xFFF1F2F6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(child: _buildFechaButton()),
                            const SizedBox(width: 8),
                            Expanded(child: _buildHoraButton()),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_submitError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _submitError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_esEdicion ? 'Guardar cambios' : 'Agregar'),
                ),
              ),

              if (_esEdicion && widget.onDelete != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  title: const Text('Eliminar tarea'),
                                  content: const Text(
                                    '¿Seguro que deseas eliminar esta tarea? '
                                    'Esta acción no se puede deshacer.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed != true) return;

                            setState(() => _submitting = true);

                            try {
                              await widget.onDelete!.call();
                              if (!mounted) return;
                              Navigator.of(context).pop('deleted');
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _submitting = false);
                            }
                          },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Eliminar tarea',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F2F6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFechaButton() {
    String texto;
    if (_fechaEntrega == null) {
      texto = 'Fecha de entrega';
    } else {
      final f = _fechaEntrega!;
      texto = '${f.day.toString().padLeft(2, '0')}/'
          '${f.month.toString().padLeft(2, '0')}/'
          '${f.year}';
    }

    return InkWell(
      onTap: _seleccionarFecha,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoraButton() {
    String texto;
    if (_horaEntrega == null) {
      texto = 'Hora de entrega';
    } else {
      texto = _formatearHora(_horaEntrega!);
    }

    return InkWell(
      onTap: _seleccionarHora,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
