import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Future<void>? _initFuture;

  Future<String> getSelectedAdzan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_adzan') ?? 'bilal';
  }

  Future<void> setSelectedAdzan(String soundFileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_adzan', soundFileName);
  }

  Future<bool> isAdzanMuted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('mute_adzan') ?? false;
  }

  Future<void> setAdzanMuted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mute_adzan', value);
  }

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initFuture != null) return _initFuture!;

    _initFuture = _performInit();
    return _initFuture!;
  }

  Future<void> _performInit() async {
    debugPrint('NotificationService: Initializing...');
    tz_data.initializeTimeZones();
    try {
      final dynTimeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(dynTimeZoneName.toString()));
      debugPrint('NotificationService: Timezone set to $dynTimeZoneName');
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to get local timezone, defaulting to Asia/Jakarta',
      );
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    final bool? initialized = await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint(
          'NotificationService: Notification tapped: ${details.payload}',
        );
      },
    );
    debugPrint('NotificationService: Plugin initialized: $initialized');

    if (defaultTargetPlatform == TargetPlatform.android) {

      await _ensureAndroidChannel(
        channelId: 'waqt_general_v2',
        channelName: 'WAQT Notifications',
      );

      await _ensureAndroidChannel(
        channelId: 'waqt_prayer_v3',
        channelName: 'Jadwal Sholat',
      );
    }

    _isInitialized = true;
    _initFuture = null;
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint('NotificationService: Requesting permissions...');
      await Permission.notification.request();

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final hasExactAlarm =
            await androidPlugin.canScheduleExactNotifications() ?? false;
        if (!hasExactAlarm) {
          debugPrint(
            'NotificationService: Requesting exact alarm permission from OS...',
          );
          await androidPlugin.requestExactAlarmsPermission();
        }
      }

      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      if (!(await Permission.ignoreBatteryOptimizations.isGranted)) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  Future<void> _ensureAndroidChannel({
    required String channelId,
    required String channelName,
    String? soundFile,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        channelName,
        importance: Importance.max,
        playSound: true,
        sound: soundFile != null
            ? RawResourceAndroidNotificationSound(soundFile)
            : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    bool useAdzanChannel = false,
  }) async {
    await init();

    NotificationDetails platformDetails;
    if (useAdzanChannel) {
      final selectedAdzan = await getSelectedAdzan();
      final isMuted = await isAdzanMuted();
      final channelId = 'waqt_prayer_$selectedAdzan';

      if (!isMuted) {
        await _ensureAndroidChannel(
          channelId: channelId,
          channelName: 'Jadwal Sholat',
          soundFile: selectedAdzan,
        );
      }

      platformDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          isMuted ? 'waqt_prayer_v3' : channelId,
          'Jadwal Sholat',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'Waqt Prayer',
          playSound: true,
          sound: isMuted
              ? null
              : RawResourceAndroidNotificationSound(selectedAdzan),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: isMuted ? null : '$selectedAdzan.caf',
        ),
      );
    } else {
      platformDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'waqt_general_v2',
          'WAQT Notifications',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          ticker: 'Waqt General',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );
    }

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  Future<void> schedulePrayerNotifications(Map<String, dynamic> timings) async {
    if (kIsWeb) return;
    await init();

    final nowTz = tz.TZDateTime.now(tz.local);
    final prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];

    debugPrint('NotificationService: Scheduling daily prayers. Now: $nowTz');

    for (int i = 0; i < prayerNames.length; i++) {
      final name = prayerNames[i];
      final timeStr = timings[name];
      if (timeStr == null) continue;

      final parts = timeStr.split(':');
      var prayerTime = tz.TZDateTime(
        tz.local,
        nowTz.year,
        nowTz.month,
        nowTz.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      // Jika waktu sudah lewat hari ini, jadwalkan untuk besok
      if (prayerTime.isBefore(nowTz)) {
        prayerTime = prayerTime.add(const Duration(days: 1));
      }

      debugPrint('NotificationService: [SCHEDULED] $name at $prayerTime');
      await _scheduleNotification(
        id: i,
        title: 'Waktu $name Tiba!',
        body: 'Mari tunaikan ibadah sholat $name sekarang.',
        scheduledDate: prayerTime,
        isAdzan: true,
      );

      // Logika Peringatan dan Qada (termasuk transisi Isya -> Subuh besok)
      final nextIndex = (i + 1) % prayerNames.length;
      final nextName = prayerNames[nextIndex];
      final nextTimeStr = timings[nextName];

      if (nextTimeStr != null) {
        final nextParts = nextTimeStr.split(':');
        var nextPrayerTime = tz.TZDateTime(
          tz.local,
          nowTz.year,
          nowTz.month,
          nowTz.day,
          int.parse(nextParts[0]),
          int.parse(nextParts[1]),
        );

        // Pastikan waktu sholat berikutnya adalah setelah sholat saat ini
        if (nextIndex == 0 || nextPrayerTime.isBefore(prayerTime)) {
          nextPrayerTime = nextPrayerTime.add(const Duration(days: 1));
        }

        // 1. Peringatan (15 menit sebelum sholat berikutnya)
        var warningTime = nextPrayerTime.subtract(const Duration(minutes: 15));
        if (warningTime.isAfter(nowTz)) {
          debugPrint(
            'NotificationService: [SCHEDULED_WARNING] for $name at $warningTime',
          );
          await _scheduleNotification(
            id: i + 100,
            title: 'Waktu $name Segera Berakhir',
            body: 'Tinggal 15 menit lagi sebelum waktu $nextName tiba.',
            scheduledDate: warningTime,
          );
        }

        // 2. Notifikasi Terlewat (Qada) - 20 detik setelah sholat berikutnya tiba
        var missedAlertTime = nextPrayerTime.add(const Duration(seconds: 20));
        if (missedAlertTime.isAfter(nowTz)) {
          debugPrint(
            'NotificationService: [SCHEDULED_QADA_ALERT] for $name at $missedAlertTime',
          );
          await _scheduleNotification(
            id: i + 200,
            title: 'Sholat $name Terlewat',
            body: 'Waktu $name telah habis. Sholat ini masuk ke daftar Qada.',
            scheduledDate: missedAlertTime,
          );
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isAdzan = false,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    NotificationDetails platformDetails;
    if (isAdzan) {
      final selectedAdzan = await getSelectedAdzan();
      final isMuted = await isAdzanMuted();
      final channelId = 'waqt_prayer_$selectedAdzan';

      if (!isMuted) {
        await _ensureAndroidChannel(
          channelId: channelId,
          channelName: 'Jadwal Sholat',
          soundFile: selectedAdzan,
        );
      }

      platformDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          isMuted ? 'waqt_prayer_v3' : channelId,
          'Jadwal Sholat',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Waqt Prayer',
          playSound: true,
          sound: isMuted
              ? null
              : RawResourceAndroidNotificationSound(selectedAdzan),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: isMuted ? null : '$selectedAdzan.caf',
        ),
      );
    } else {
      platformDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'waqt_prayer_v3',
          'Jadwal Sholat',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Waqt General',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
        'NotificationService: Successfully scheduled alarm for ID $id at $tzDate',
      );
    } catch (e) {
      debugPrint(
        'NotificationService: Fallback to inexact alarm for ID $id: $e',
      );
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> showQadaAlert(String prayerName) async {
    final prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
    int index = prayerNames.indexOf(prayerName);
    if (index == -1) index = 0;

    await showNotification(
      id: 1000 + index,
      title: 'Sholat $prayerName Terlewat',
      body: 'Waktu $prayerName telah habis. Sholat ini masuk ke daftar Qada.',
    );
  }

  Future<void> showStreakResetAlert() async {
    await showNotification(
      id: 9999,
      title: 'Streak Terhenti',
      body:
          'Sayang sekali, streak Anda terhenti karena ada sholat Qada yang tidak tuntas hari ini.',
    );
  }

  Future<void> cancelSpecificQadaAlert(String prayerName) async {
    final prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
    int index = prayerNames.indexOf(prayerName);
    if (index != -1) {
      await _notificationsPlugin.cancel(id: index + 200);
      debugPrint(
        'NotificationService: Cancelled scheduled Qada alert for $prayerName (ID: ${index + 200})',
      );
    }
  }
}
