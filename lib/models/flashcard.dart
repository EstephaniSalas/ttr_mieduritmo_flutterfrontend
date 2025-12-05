// lib/models/flashcard.dart
class Flashcard {
  final String id;
  final String usuarioId;
  final String materiaId;
  String delanteFlashcard;
  String reversoFlashcard;

  Flashcard({
    required this.id,
    required this.usuarioId,
    required this.materiaId,
    required this.delanteFlashcard,
    required this.reversoFlashcard,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final uid = json['uid'] ?? json['_id'];

    // Puede venir como string o como objeto populado
    String _parseId(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) {
        return (v['uid'] ?? v['_id'] ?? '') as String;
      }
      return '';
    }

    return Flashcard(
      id: uid as String,
      usuarioId: _parseId(json['usuario']),
      materiaId: _parseId(json['materia']),
      delanteFlashcard: json['delanteFlashcard'] ?? '',
      reversoFlashcard: json['reversoFlashcard'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': id,
        'usuario': usuarioId,
        'materia': materiaId,
        'delanteFlashcard': delanteFlashcard,
        'reversoFlashcard': reversoFlashcard,
      };
}
