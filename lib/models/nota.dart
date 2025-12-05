// lib/models/nota.dart
class Nota {
  final String id;
  final String nombreNota;
  final String contenidoNota;

  Nota({
    required this.id,
    required this.nombreNota,
    required this.contenidoNota,
  });

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: (json['uid'] ?? json['_id'] ?? '').toString(),
      nombreNota: (json['nombreNota'] ?? '').toString(),
      contenidoNota: (json['contenidoNota'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreNota': nombreNota,
      'contenidoNota': contenidoNota,
    };
  }

  Nota copyWith({
    String? id,
    String? nombreNota,
    String? contenidoNota,
  }) {
    return Nota(
      id: id ?? this.id,
      nombreNota: nombreNota ?? this.nombreNota,
      contenidoNota: contenidoNota ?? this.contenidoNota,
    );
  }
}
