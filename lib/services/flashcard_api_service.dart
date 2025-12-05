// lib/services/flashcard_api_service.dart
import 'package:dio/dio.dart';

import '../models/materia.dart';
import '../models/flashcard.dart';

class FlashcardsService {
  final Dio _dio;
  final String baseUrl;

  FlashcardsService(
    this._dio, {
    this.baseUrl = 'http://10.0.2.2:8080/api',
  });

  Map<String, dynamic> get _authHeaders =>
      {'x-token': _dio.options.headers['x-token']};

  // --- 1) Materias que tienen flashcards para el usuario ---
  Future<List<Materia>> obtenerMateriasConFlashcards({
    required String userId,
  }) async {
    final resp = await _dio.get(
      '$baseUrl/flashcards/materias/idUsuario/$userId',
      options: Options(headers: _authHeaders),
    );

    final data = resp.data;
    final list = (data['materias'] as List? ?? []);
    return list.map((e) => Materia.fromJson(e)).toList();
  }

  // --- 2) Todas las flashcards por materia ---
  Future<List<Flashcard>> obtenerFlashcardsPorMateria({
    required String userId,
    required String materiaId,
  }) async {
    final resp = await _dio.get(
      '$baseUrl/flashcards/idUsuario/$userId/idMateria/$materiaId',
      options: Options(headers: _authHeaders),
    );

    final data = resp.data;
    final list = (data['flashcards'] as List? ?? []);
    return list.map((e) => Flashcard.fromJson(e)).toList();
  }

  // --- 3) Crear flashcard ---
  Future<Flashcard> crearFlashcard({
    required String userId,
    required String materiaId,
    required String delante,
    required String reverso,
  }) async {
    final resp = await _dio.post(
      '$baseUrl/flashcards/idUsuario/$userId/idMateria/$materiaId',
      options: Options(headers: _authHeaders),
      data: {
        'delanteFlashcard': delante,
        'reversoFlashcard': reverso,
      },
    );

    final data = resp.data['flashcardCreada'] ??
        resp.data['flashcard'] ??
        resp.data;
    return Flashcard.fromJson(data);
  }

  // --- 4) Actualizar flashcard ---
  Future<Flashcard> actualizarFlashcard({
    required String userId,
    required String flashcardId,
    required String delante,
    required String reverso,
  }) async {
    final body = <String, dynamic>{};
    if (delante.isNotEmpty) body['delanteFlashcard'] = delante;
    if (reverso.isNotEmpty) body['reversoFlashcard'] = reverso;

    final resp = await _dio.put(
      '$baseUrl/flashcards/idUsuario/$userId/idFlashcard/$flashcardId',
      options: Options(headers: _authHeaders),
      data: body,
    );

    final data = resp.data['flashcard'] ?? resp.data;
    return Flashcard.fromJson(data);
  }

  // --- 5) Eliminar una flashcard ---
  Future<void> eliminarFlashcard({
    required String userId,
    required String flashcardId,
  }) async {
    await _dio.delete(
      '$baseUrl/flashcards/idUsuario/$userId/idFlashcard/$flashcardId',
      options: Options(headers: _authHeaders),
      data: {'confirmacion': true},
    );
  }

  // --- 6) Eliminar todas las flashcards de una materia ---
  Future<void> eliminarFlashcardsPorMateria({
    required String userId,
    required String materiaId,
  }) async {
    await _dio.delete(
      '$baseUrl/flashcards/idUsuario/$userId/idMateria/$materiaId',
      options: Options(headers: _authHeaders),
      data: {'confirmacion': true},
    );
  }

  // --- 7) Eliminar TODAS las flashcards del usuario ---
  Future<void> eliminarTodasFlashcardsUsuario({
    required String userId,
  }) async {
    await _dio.delete(
      '$baseUrl/flashcards/idUsuario/$userId',
      options: Options(headers: _authHeaders),
      data: {'confirmacion': true},
    );
  }
}
