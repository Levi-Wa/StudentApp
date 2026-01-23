import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive/hive.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _settingsBox = 'notification_settings';

  // Диапазоны ID для разных типов уведомлений
  static const int _scheduleBaseId = 1000;
  static const int _noteBaseId = 2000;
  static const int _lessonBaseId = 3000;

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    final bool? initialized = await _notifications.initialize(settings);

    // Создаем каналы уведомлений
    await _createNotificationChannels();

    // Очищаем старые уведомления при запуске для избежания проблем
    try {
      await _notifications.cancelAll();
    } catch (e) {
      // ignore cleanup errors
    }
  }
  
  static Future<void> _createNotificationChannels() async {
    const androidChannel1 = AndroidNotificationChannel(
      'schedule_channel',
      'Уведомления расписания',
      description: 'Уведомления об изменениях в расписании',
      importance: Importance.max,
    );

    const androidChannel2 = AndroidNotificationChannel(
      'notes_channel',
      'Уведомления заметок',
      description: 'Уведомления о заметках',
      importance: Importance.max,
    );

    const androidChannel3 = AndroidNotificationChannel(
      'lessons_channel',
      'Уведомления о занятиях',
      description: 'Уведомления о предстоящих занятиях',
      importance: Importance.max,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel1);
      await androidPlugin.createNotificationChannel(androidChannel2);
      await androidPlugin.createNotificationChannel(androidChannel3);
    }
  }

  static Future<void> scheduleScheduleNotification(String title, String body, DateTime scheduledTime, {int? notificationId}) async {
    if (!await _isScheduleNotificationsEnabled()) return;

    final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000) + _scheduleBaseId;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_channel',
          'Уведомления расписания',
          channelDescription: 'Уведомления об изменениях в расписании',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleNoteNotification(String title, String body, DateTime scheduledTime, {int? notificationId}) async {
    if (!await _isNoteNotificationsEnabled()) return;

    final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000) + _noteBaseId;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'notes_channel',
          'Уведомления заметок',
          channelDescription: 'Уведомления о заметках',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  static Future<void> scheduleLessonNotification(String title, String body, DateTime scheduledTime, {int? notificationId}) async {
    if (!await _isScheduleNotificationsEnabled()) return;

    final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000) + _lessonBaseId;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lessons_channel',
          'Уведомления о занятиях',
          channelDescription: 'Уведомления о предстоящих занятиях',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showImmediateNotification(String title, String body) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_channel',
          'Уведомления расписания',
          channelDescription: 'Уведомления об изменениях в расписании',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
      ),
    );
  }
  
  static Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
  }
  
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  static Future<void> cancelAllScheduleNotifications() async {
    // Отменяем все уведомления расписания (ID от _scheduleBaseId до _noteBaseId)
    for (int i = _scheduleBaseId; i < _noteBaseId; i++) {
      await _notifications.cancel(i);
    }
  }
  
  static Future<void> cancelAllLessonNotifications() async {
    try {
      // Отменяем все уведомления о занятиях (ID от _lessonBaseId)
      for (int i = _lessonBaseId; i < _lessonBaseId + 10000; i++) {
        await _notifications.cancel(i);
      }
    } catch (e) {
      // В случае ошибки пробуем более мягкий подход - отменить по одному
      try {
        await _notifications.cancelAll();
      } catch (e2) {
        // ignore
      }
    }
  }
  
  static int generateNoteNotificationId(String noteId) {
    // Генерируем уникальный ID на основе ID заметки
    return _noteBaseId + noteId.hashCode.abs() % 100000;
  }
  
  static int generateLessonNotificationId(String date, String time) {
    // Генерируем уникальный ID на основе даты и времени занятия
    return _lessonBaseId + (date + time).hashCode.abs() % 100000;
  }

  static Future<bool> _isScheduleNotificationsEnabled() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('schedule_notifications', defaultValue: false);
  }

  static Future<bool> _isNoteNotificationsEnabled() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('note_notifications', defaultValue: false);
  }

  static Future<void> setScheduleNotifications(bool enabled) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('schedule_notifications', enabled);
  }

  static Future<void> setNoteNotifications(bool enabled) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('note_notifications', enabled);
  }

  static Future<int> getNotificationPeriod() async {
    final box = await Hive.openBox(_settingsBox);
    final period = box.get('notification_period', defaultValue: 'За день');
    switch (period) {
      case 'За 3 дня': return 3;
      case 'За 7 дней': return 7;
      default: return 1;
    }
  }

  static Future<void> setNotificationPeriod(String period) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('notification_period', period);
  }
}