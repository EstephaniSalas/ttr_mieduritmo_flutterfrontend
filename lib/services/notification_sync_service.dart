// lib/services/notification_sync_service.dart
import 'package:dio/dio.dart';
import 'notification_service.dart';

/// Servicio para sincronizar notificaciones de eventos y tareas futuras
class NotificationSyncService {
  final Dio dio;
  final NotificationService notificationService;

  NotificationSyncService(this.dio, this.notificationService);

  /// Sincronizar TODAS las notificaciones (tareas + eventos futuros)
  /// Llamar esto después del login o al iniciar la app
  Future<void> sincronizarTodasNotificaciones(String userId) async {
    try {
      print('🔄 Iniciando sincronización de notificaciones...');

      // Cancelar todas las notificaciones previas
      await notificationService.cancelarTodasNotificaciones();

      // Sincronizar tareas futuras
      await sincronizarTareasFuturas(userId);

      // Sincronizar eventos futuros
      await sincronizarEventosFuturos(userId);

      print('✅ Sincronización de notificaciones completada');
    } catch (e) {
      print('❌ Error en sincronización de notificaciones: $e');
    }
  }

  /// Sincronizar solo TAREAS futuras
  Future<void> sincronizarTareasFuturas(String userId) async {
    try {
      final resp = await dio.get('/tareas/idUsuario/$userId/futuras');

      if (resp.statusCode == 200) {
        final List<dynamic> tareas = resp.data['tareas'] ?? [];

        print('📋 Programando notificaciones para ${tareas.length} tareas futuras');

        for (var tareaJson in tareas) {
          final tareaId = tareaJson['uid'] as String;
          final nombreTarea = tareaJson['nombreTarea'] as String;
          final descripcionTarea = (tareaJson['descripcionTarea'] ?? '') as String;
          final tipoTarea = tareaJson['tipoTarea'] as String;
          final fechaHoraCompletaStr = tareaJson['fechaHoraCompleta'] as String;

          final fechaHoraCompleta = DateTime.parse(fechaHoraCompletaStr);

          // Programar notificaciones para esta tarea
          await notificationService.programarNotificacionesTarea(
            tareaId: tareaId,
            nombreTarea: nombreTarea,
            descripcion: descripcionTarea,
            fechaHoraEntrega: fechaHoraCompleta,
            tipoTarea: tipoTarea,
          );
        }

        print('✅ ${tareas.length} tareas programadas con notificaciones');
      }
    } catch (e) {
      print('❌ Error sincronizando tareas futuras: $e');
      rethrow;
    }
  }

  /// Sincronizar solo EVENTOS futuros
  Future<void> sincronizarEventosFuturos(String userId) async {
    try {
      final resp = await dio.get('/eventos/idUsuario/$userId/futuros');

      if (resp.statusCode == 200) {
        final List<dynamic> eventos = resp.data['eventos'] ?? [];

        print('📅 Programando notificaciones para ${eventos.length} eventos futuros');

        for (var eventoJson in eventos) {
          final eventoId = eventoJson['uid'] as String;
          final tituloEvento = eventoJson['tituloEvento'] as String;
          final descripcionEvento = (eventoJson['descripcionEvento'] ?? '') as String;
          final importante = eventoJson['importante'] as bool? ?? false;
          final fechaHoraCompletaStr = eventoJson['fechaHoraCompleta'] as String;

          final fechaHoraCompleta = DateTime.parse(fechaHoraCompletaStr);

          // Programar notificaciones para este evento
          await notificationService.programarNotificacionesEvento(
            eventoId: eventoId,
            titulo: tituloEvento,
            descripcion: descripcionEvento,
            fechaHoraInicio: fechaHoraCompleta,
            importante: importante,
          );
        }

        print('✅ ${eventos.length} eventos programados con notificaciones');
      }
    } catch (e) {
      print('❌ Error sincronizando eventos futuros: $e');
      rethrow;
    }
  }

  /// Obtener el total de notificaciones programadas
  Future<int> obtenerTotalNotificacionesProgramadas() async {
    final pendientes = await notificationService.obtenerNotificacionesPendientes();
    return pendientes.length;
  }
}