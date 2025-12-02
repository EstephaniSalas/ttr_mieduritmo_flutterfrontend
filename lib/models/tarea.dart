// lib/models/tarea.dart
class Tarea {
  final String id;
  final String nombreTarea;
  final String? materiaId;
  final String? materiaNombre;
  final String descripcionTarea;
  final String tipoTarea; // "Tarea" | "Proyecto" | "Examen"
  final DateTime fechaEntregaTarea;
  final String horaEntregaTarea; // "HH:MM"
  final String estatusTarea; // "Pendiente" | "Completada" | "Vencida"

  Tarea({
    required this.id,
    required this.nombreTarea,
    this.materiaId,
    this.materiaNombre,
    required this.descripcionTarea,
    required this.tipoTarea,
    required this.fechaEntregaTarea,
    required this.horaEntregaTarea,
    required this.estatusTarea,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    final dynamic materiaJson = json['materiaTarea'];

    String? materiaId;
    String? materiaNombre;

    if (materiaJson is Map<String, dynamic>) {
      materiaId = materiaJson['uid'] ?? materiaJson['_id'];
      materiaNombre = materiaJson['nombreMateria'];
    } else if (materiaJson is String) {
      materiaId = materiaJson;
    }

    return Tarea(
      id: (json['uid'] ?? json['_id']).toString(),
      nombreTarea: (json['nombreTarea'] ?? '') as String,
      materiaId: materiaId,
      materiaNombre: materiaNombre,
      descripcionTarea: (json['descripcionTarea'] ?? '') as String,
      tipoTarea: (json['tipoTarea'] ?? 'Tarea') as String,
      fechaEntregaTarea: DateTime.parse(json['fechaEntregaTarea'] as String),
      horaEntregaTarea: (json['horaEntregaTarea'] ?? '') as String,
      estatusTarea: (json['estatusTarea'] ?? 'Pendiente') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'nombreTarea': nombreTarea,
      'materiaTarea': materiaId,
      'descripcionTarea': descripcionTarea,
      'tipoTarea': tipoTarea,
      'fechaEntregaTarea': fechaEntregaTarea.toIso8601String(),
      'horaEntregaTarea': horaEntregaTarea,
      'estatusTarea': estatusTarea,
    };
  }
}
