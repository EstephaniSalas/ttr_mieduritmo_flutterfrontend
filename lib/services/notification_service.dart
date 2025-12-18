// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar zonas horarias
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    // Configuración para Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos
    await _requestPermissions();

    _initialized = true;
  }

  /// Solicitar permisos de notificaciones
  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Para Android 13+ (API 33+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  /// Manejar cuando el usuario toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    print('🔔 Notificación tocada con payload: $payload');
    // Aquí puedes navegar a una pantalla específica según el payload
  }

  /// Programar notificaciones para una TAREA
  Future<void> programarNotificacionesTarea({
    required String tareaId,
    required String nombreTarea,
    required String descripcion,
    required DateTime fechaHoraEntrega,
    required String tipoTarea, // 'Tarea', 'Proyecto', 'Examen'
  }) async {
    // Cancelar notificaciones previas de esta tarea
    await cancelarNotificacionesTarea(tareaId);

    final now = DateTime.now();

    // Emojis según tipo
    String emoji = '📝';
    if (tipoTarea == 'Proyecto') {
      emoji = '📊';
    } else if (tipoTarea == 'Examen') {
      emoji = '📖';
    }

    // Lista de recordatorios: 7 días, 1 día, 1 hora antes y al momento
    final notificaciones = [
      {
        'offset': const Duration(days: 7),
        'title': '$emoji $tipoTarea en 7 días: $nombreTarea',
        'body': descripcion.isEmpty ? 'Prepárate con tiempo' : descripcion,
        'id': _generarIdNotificacion(tareaId, 1),
      },
      {
        'offset': const Duration(days: 1),
        'title': '$emoji $tipoTarea mañana: $nombreTarea',
        'body': descripcion.isEmpty ? '¡No lo olvides!' : descripcion,
        'id': _generarIdNotificacion(tareaId, 2),
      },
      {
        'offset': const Duration(hours: 1),
        'title': '⏰ ¡Pronto! $tipoTarea en 1 hora',
        'body': nombreTarea,
        'id': _generarIdNotificacion(tareaId, 3),
      },
      {
        'offset': Duration.zero,
        'title': '✨ ¡Ahora! Es hora de entregar: $nombreTarea',
        'body': 'Fecha de entrega: ${_formatearFechaHora(fechaHoraEntrega)}',
        'id': _generarIdNotificacion(tareaId, 4),
      },
    ];

    // Programar cada notificación
    for (var notification in notificaciones) {
      final scheduledDate =
          fechaHoraEntrega.subtract(notification['offset'] as Duration);

      // Solo programar si la fecha es futura
      if (scheduledDate.isAfter(now)) {
        await _scheduleNotification(
          id: notification['id'] as int,
          title: notification['title'] as String,
          body: notification['body'] as String,
          scheduledDate: scheduledDate,
          payload: 'tarea:$tareaId:${tipoTarea.toLowerCase()}',
        );
      }
    }
  }

  /// Programar notificaciones para un EVENTO
  Future<void> programarNotificacionesEvento({
    required String eventoId,
    required String titulo,
    required String descripcion,
    required DateTime fechaHoraInicio,
    required bool importante,
  }) async {
    // Cancelar notificaciones previas de este evento
    await cancelarNotificacionesEvento(eventoId);

    final now = DateTime.now();

    String emoji = importante ? '⭐' : '📅';

    // Lista de recordatorios
    final notificaciones = [
      {
        'offset': const Duration(days: 7),
        'title': '$emoji Evento en 7 días: $titulo',
        'body': descripcion.isEmpty ? 'Prepárate con tiempo' : descripcion,
        'id': _generarIdNotificacion(eventoId, 1),
      },
      {
        'offset': const Duration(days: 1),
        'title': '$emoji Evento mañana: $titulo',
        'body': descripcion.isEmpty ? 'Es mañana' : descripcion,
        'id': _generarIdNotificacion(eventoId, 2),
      },
      {
        'offset': const Duration(hours: 1),
        'title': '⏰ Evento en 1 hora: $titulo',
        'body': descripcion,
        'id': _generarIdNotificacion(eventoId, 3),
      },
      {
        'offset': Duration.zero,
        'title': '✨ ¡Ahora! Evento: $titulo',
        'body': 'Comienza: ${_formatearFechaHora(fechaHoraInicio)}',
        'id': _generarIdNotificacion(eventoId, 4),
      },
    ];

    // Programar cada notificación
    for (var notification in notificaciones) {
      final scheduledDate =
          fechaHoraInicio.subtract(notification['offset'] as Duration);

      if (scheduledDate.isAfter(now)) {
        await _scheduleNotification(
          id: notification['id'] as int,
          title: notification['title'] as String,
          body: notification['body'] as String,
          scheduledDate: scheduledDate,
          payload: 'evento:$eventoId',
        );
      }
    }
  }

  /// Programar una notificación individual
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'eventos_educativos',
            'Eventos Educativos',
            channelDescription:
                'Notificaciones de tareas, exámenes y eventos',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(body),
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Notificación programada: $title para ${_formatearFechaHora(scheduledDate)}');
    } catch (e) {
      print('❌ Error al programar notificación: $e');
    }
  }

  /// Generar ID único para notificaciones
  /// Usa el hash del ID de la tarea/evento + número de notificación (1-4)
  int _generarIdNotificacion(String itemId, int notificationNumber) {
    // Convertir el ID a un número único
    final hash = itemId.hashCode.abs();
    // Asegurar que el ID final esté en el rango de int32
    return (hash % 100000) * 10 + notificationNumber;
  }

  /// Cancelar todas las notificaciones de una tarea específica
  Future<void> cancelarNotificacionesTarea(String tareaId) async {
    for (int i = 1; i <= 4; i++) {
      final notificationId = _generarIdNotificacion(tareaId, i);
      await _notifications.cancel(notificationId);
    }
    print('🗑️ Notificaciones canceladas para tarea: $tareaId');
  }

  /// Cancelar todas las notificaciones de un evento específico
  Future<void> cancelarNotificacionesEvento(String eventoId) async {
    for (int i = 1; i <= 4; i++) {
      final notificationId = _generarIdNotificacion(eventoId, i);
      await _notifications.cancel(notificationId);
    }
    print('🗑️ Notificaciones canceladas para evento: $eventoId');
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelarTodasNotificaciones() async {
    await _notifications.cancelAll();
    print('🗑️ Todas las notificaciones canceladas');
  }

  /// Obtener todas las notificaciones pendientes
  Future<List<PendingNotificationRequest>> obtenerNotificacionesPendientes() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Mostrar notificación inmediata (para testing)
  Future<void> mostrarNotificacionInmediata({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Formatear fecha y hora para mostrar
  String _formatearFechaHora(DateTime dt) {
    final fecha = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
    final hora = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$fecha a las $hora';
  }
}