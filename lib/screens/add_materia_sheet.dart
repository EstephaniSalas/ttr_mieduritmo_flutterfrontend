import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../theme/app_colors.dart' show AppColors;

class AddMateriaPayload {
  final String? id; // null = crear, no null = editar
  final String nombre;
  final String profesor;
  final String edificio;
  final String salon;
  final List<HorarioMateria> horarios;

  AddMateriaPayload({
    this.id,
    required this.nombre,
    required this.profesor,
    required this.edificio,
    required this.salon,
    required this.horarios,
  });
}

class AddMateriaSheet extends StatefulWidget {
  final Future<Materia> Function(AddMateriaPayload payload) onSubmit;
  final Future<void> Function()? onDelete; // solo en modo edición
  final Materia? materiaInicial;

  const AddMateriaSheet({
    super.key,
    required this.onSubmit,
    this.onDelete,
    this.materiaInicial,
  });

  @override
  State<AddMateriaSheet> createState() => _AddMateriaSheetState();
}

class _AddMateriaSheetState extends State<AddMateriaSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _profesorCtrl = TextEditingController();
  final _edificioCtrl = TextEditingController();
  final _salonCtrl = TextEditingController();

  String? _submitError;

  final List<String> _diasSemana = const [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  final Map<String, bool> _selected = {};
  final Map<String, TimeOfDay?> _startTimes = {};
  final Map<String, TimeOfDay?> _endTimes = {};

  bool _submitting = false;
  bool get _isEdit => widget.materiaInicial != null;

  @override
  void initState() {
    super.initState();

    for (final d in _diasSemana) {
      _selected[d] = false;
      _startTimes[d] = null;
      _endTimes[d] = null;
    }

    if (widget.materiaInicial != null) {
      final m = widget.materiaInicial!;
      _nombreCtrl.text = m.nombre;
      _profesorCtrl.text = m.profesor;
      _edificioCtrl.text = m.edificio;
      _salonCtrl.text = m.salon;

      for (final h in m.horarios) {
        if (!_selected.containsKey(h.dia)) continue;
        _selected[h.dia] = true;

        TimeOfDay _parse(String hhmm) {
          final parts = hhmm.split(':');
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }

        _startTimes[h.dia] = _parse(h.horaInicio);
        _endTimes[h.dia] = _parse(h.horaFin);
      }
    }
    _submitError = null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _profesorCtrl.dispose();
    _edificioCtrl.dispose();
    _salonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(String dia, bool isStart) async {
  final initial = isStart 
      ? (_startTimes[dia] ?? const TimeOfDay(hour: 9, minute: 0))
      : (_endTimes[dia] ?? const TimeOfDay(hour: 10, minute: 0));

  int hour = initial.hour % 12;
  if (hour == 0) hour = 12;
  int minute = initial.minute;
  bool isAm = initial.hour < 12;

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Seleccionar hora', textAlign: TextAlign.center),
        content: SingleChildScrollView( // Añadido para evitar overflow
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite, // Ocupar todo el ancho disponible
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
                  children: [
                    // Selector de hora y minutos
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
                              width: 70, // Un poco más ancho
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hour.toString().padLeft(2, '0'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            const Text('Hora', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        
                        // Minutos
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_drop_up),
                              onPressed: () {
                                setState(() {
                                  minute = minute == 55 ? 0 : minute + 5;
                                });
                              },
                            ),
                            Container(
                              width: 70,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                minute.toString().padLeft(2, '0'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_drop_down),
                              onPressed: () {
                                setState(() {
                                  minute = minute == 0 ? 55 : minute - 5;
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text('Min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Botones AM/PM
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() { 
                              isAm = true; 
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
                          onTap: () {
                            setState(() { 
                              isAm = false; 
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
                    
                    const SizedBox(height: 8), // Espacio extra al final
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Convertir a formato 24h
              int hour24 = hour;
              if (hour == 12) {
                hour24 = isAm ? 0 : 12;
              } else {
                hour24 = isAm ? hour : hour + 12;
              }
              
              final selectedTime = TimeOfDay(hour: hour24, minute: minute);
              
              // Necesitamos llamar al setState del widget padre, no del StatefulBuilder
              if (isStart) {
                _startTimes[dia] = selectedTime;
              } else {
                _endTimes[dia] = selectedTime;
              }
              
              // Llamar al setState del widget padre
              if (mounted) {
                setState(() {});
              }
              
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      );
    },
  );
}

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final List<HorarioMateria> horarios = [];

    for (final d in _diasSemana) {
      if (!_selected[d]!) continue;
      final start = _startTimes[d];
      final end = _endTimes[d];
      if (start == null || end == null) continue;

      final startMin = start.hour * 60 + start.minute;
      final endMin = end.hour * 60 + end.minute;
      if (startMin >= endMin) continue;

      horarios.add(
        HorarioMateria(
          dia: d,
          horaInicio: _formatTime(start),
          horaFin: _formatTime(end),
        ),
      );
    }

    if (horarios.isEmpty) {
      setState(() {
        _submitError = 'Selecciona al menos un día y horario válido';
      });
      return;
    }

    final payload = AddMateriaPayload(
      id: widget.materiaInicial?.id,
      nombre: _nombreCtrl.text.trim(),
      profesor: _profesorCtrl.text.trim(),
      edificio: _edificioCtrl.text.trim(),
      salon: _salonCtrl.text.trim(),
      horarios: horarios,
    );

    setState(() {
      _submitting = true;
      _submitError = null; // limpiar error anterior
    });

    try {
      final materia = await widget.onSubmit(payload);
      if (mounted) {
        Navigator.of(context).pop(materia);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // aquí te llegará el mensaje del backend (traslapes, etc.)
        _submitError = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _isEdit ? 'Editar materia' : 'Agregar materia';

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
                        _buildTextField(
                          _nombreCtrl,
                          'Nombre de la materia',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _profesorCtrl,
                          'Nombre del profesor',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(_edificioCtrl, 'Edificio'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTextField(_salonCtrl, 'Salón'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Día y horario',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _diasSemana.length,
                          itemBuilder: (context, index) {
                            final dia = _diasSemana[index];
                            final selected = _selected[dia]!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: selected,
                                          activeColor: AppColors.black,
                                          onChanged: (v) {
                                            setState(() {
                                              _selected[dia] = v ?? false;
                                            });
                                          },
                                        ),
                                        Flexible(child: Text(dia)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTimeButton(
                                      label: 'Hora inicio',
                                      value: _formatTime(_startTimes[dia]),
                                      enabled: selected,
                                      onTap: () => _pickTime(dia, true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTimeButton(
                                      label: 'Hora fin',
                                      value: _formatTime(_endTimes[dia]),
                                      enabled: selected,
                                      onTap: () => _pickTime(dia, false),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mensaje de error debajo del formulario / botón
              if (_submitError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _submitError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

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
                      : Text(_isEdit ? 'Guardar cambios' : 'Agregar materia'),
                ),
              ),

              // BOTÓN ELIMINAR EN MODO EDICIÓN
              if (_isEdit && widget.onDelete != null) ...[
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
                                  title: const Text('Eliminar materia'),
                                  content: const Text(
                                    '¿Seguro que deseas eliminar esta materia? '
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

                            setState(() {
                              _submitting = true;
                            });

                            try {
                              await widget.onDelete!.call();
                              if (!mounted) return;
                              // devolvemos la marca 'deleted' para que HorarioScreen
                              // actualice la lista y muestre el mensaje flotante
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
                              if (mounted) {
                                setState(() {
                                  _submitting = false;
                                });
                              }
                            }
                          },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Eliminar materia',
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
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

  Widget _buildTimeButton({
    required String label,
    required String value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF1F2F6) : const Color(0xFFE3E4E8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
