import 'package:dio/dio.dart';
import '../models/materia.dart';
import '../models/flashcard.dart';

class FlashcardsService {
  final Dio dio;

  FlashcardsService(this.dio); // Constructor simple

Materia _safeParseMateria(Map<String, dynamic> json) {
  // Crear una copia segura con valores por defecto
  final safeJson = Map<String, dynamic>.from(json);
  
  // Asegurar que todos los campos requeridos tengan valor
  safeJson['_id'] = json['_id'] ?? json['uid'] ?? '';
  safeJson['nombreMateria'] = json['nombreMateria'] ?? '';
  safeJson['profesorMateria'] = json['profesorMateria'] ?? '';
  safeJson['edificioMateria'] = json['edificioMateria'] ?? '';
  safeJson['salonMateria'] = json['salonMateria'] ?? '';
  safeJson['horariosMateria'] = json['horariosMateria'] ?? [];
  safeJson['usuario'] = json['usuario'] ?? '';
  
  try {
    return Materia.fromJson(safeJson);
  } catch (e) {
    print('❌ Error parsing materia: $e');
    print('📋 JSON problemático: $json');
    print('📋 JSON seguro: $safeJson');
    rethrow;
  }
}


  /// Materias que tienen al menos una flashcard para el usuario
 Future<List<Materia>> obtenerMateriasConFlashcards({
  required String userId,
}) async {
  try {
    final resp = await dio.get(
      '/flashcards/materias/idUsuario/$userId',
    );

    final data = resp.data;
    final list = (data['materias'] as List? ?? []);
    
    // SOLUCIÓN SEGURA
    final List<Materia> result = [];
    
    for (var item in list) {
      final json = item as Map<String, dynamic>;
      
      // Debug: imprimir qué campos son null
      final nullFields = [];
      if (json['profesorMateria'] == null) nullFields.add('profesorMateria');
      if (json['edificioMateria'] == null) nullFields.add('edificioMateria');
      if (json['salonMateria'] == null) nullFields.add('salonMateria');
      if (json['horariosMateria'] == null) nullFields.add('horariosMateria');
      
      if (nullFields.isNotEmpty) {
        print('⚠️ Campos null en ${json['nombreMateria']}: $nullFields');
      }
      
      // Corregir campos null antes de pasar a fromJson
      final safeJson = Map<String, dynamic>.from(json);
      safeJson['profesorMateria'] = json['profesorMateria'] ?? '';
      safeJson['edificioMateria'] = json['edificioMateria'] ?? '';
      safeJson['salonMateria'] = json['salonMateria'] ?? '';
      safeJson['horariosMateria'] = json['horariosMateria'] ?? [];
      
      try {
        result.add(Materia.fromJson(safeJson));
      } catch (e) {
        print('❌ Error incluso con JSON seguro: $e');
        // Continuar con siguiente materia
      }
    }
    
    print('✅ ${result.length} materias procesadas de ${list.length}');
    return result;
  } catch (e) {
    print('❌ Error: $e');
    rethrow;
  }
}


  /// Todas las flashcards por materia
  Future<List<Flashcard>> obtenerFlashcardsPorMateria({
    required String userId,
    required String materiaId,
  }) async {
    final resp = await dio.get(
      '/flashcards/idUsuario/$userId/idMateria/$materiaId',
    );

    // Estructura: { msg, total, flashcards: [...] }
    final data = resp.data;
    final list = (data['flashcards'] as List? ?? []);
    return list.map((e) => Flashcard.fromJson(e)).toList();
  }

  /// Crear flashcard
  Future<Flashcard> crearFlashcard({
    required String userId,
    required String materiaId,
    required String delante,
    required String reverso,
  }) async {
    final resp = await dio.post(
      '/flashcards/idUsuario/$userId/idMateria/$materiaId',
      data: {
        'delanteFlashcard': delante,
        'reversoFlashcard': reverso,
      },
    );

    // Estructura: { msg, flashcardCreada: {...} }
    final data =
        resp.data['flashcardCreada'] ?? resp.data['flashcard'] ?? resp.data;
    return Flashcard.fromJson(data);
  }

  /// Actualizar flashcard
  Future<Flashcard> actualizarFlashcard({
    required String userId,
    required String flashcardId,
    required String delante,
    required String reverso,
  }) async {
    final resp = await dio.put(
      '/flashcards/idUsuario/$userId/idFlashcard/$flashcardId',
      data: {
        'delanteFlashcard': delante,
        'reversoFlashcard': reverso,
      },
    );

    // Estructura: { msg, flashcard: {...} }
    final data = resp.data['flashcard'] ?? resp.data;
    return Flashcard.fromJson(data);
  }

  /// Eliminar una flashcard
  Future<void> eliminarFlashcard({
    required String userId,
    required String flashcardId,
  }) async {
    await dio.delete(
      '/flashcards/idUsuario/$userId/idFlashcard/$flashcardId',
      data: {'confirmacion': true},
    );
  }

  /// Eliminar todas las flashcards de una materia
  Future<void> eliminarFlashcardsPorMateria({
    required String userId,
    required String materiaId,
  }) async {
    await dio.delete(
      '/flashcards/idUsuario/$userId/idMateria/$materiaId',
      data: {'confirmacion': true},
    );
  }

  /// Eliminar TODAS las flashcards del usuario
  Future<void> eliminarTodasFlashcardsUsuario({
    required String userId,
  }) async {
    await dio.delete(
      '/flashcards/idUsuario/$userId',
      data: {'confirmacion': true},
    );
  }
}