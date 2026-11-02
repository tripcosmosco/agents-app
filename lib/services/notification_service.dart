import 'audio_web_helper.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;

  static const String channelCallsId = 'tripcosmos_urgent_calls';
  static const String channelCallsName = 'Incoming Calls & Live Travelers';
  static const String channelCallsDesc = 'High-priority notifications with ringtone when travelers call or inquire.';

  static const String channelLeadsId = 'tripcosmos_new_leads';
  static const String channelLeadsName = 'New Inquiries & Hot Leads';
  static const String channelLeadsDesc = 'Alerts when travelers submit quotes or chatbot leads.';

  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create high-importance Android Notification Channels
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelCallsId,
            channelCallsName,
            description: channelCallsDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelLeadsId,
            channelLeadsName,
            description: channelLeadsDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Request POST_NOTIFICATIONS permission on Android 13+
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Show Heads-Up Alert for Incoming Call
  Future<void> showIncomingCallNotification({
    required String callerName,
    required String phoneNumber,
    String? tourInterest,
  }) async {
    if (kIsWeb) {
      debugPrint('📞 Incoming Call: $callerName ($phoneNumber)');
      playRingtone();
      return;
    }
    await init();
    playRingtone();
    vibrateCallPattern();

    final androidDetails = AndroidNotificationDetails(
      channelCallsId,
      channelCallsName,
      channelDescription: channelCallsDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(
        'Traveler: $callerName\nPhone: $phoneNumber\nInterest: ${tourInterest ?? 'Varanasi Pilgrimage'}',
        contentTitle: '📞 Incoming Call: $callerName',
        summaryText: 'TripCosmos Telephony',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _localNotifications.show(
        1001,
        '📞 Incoming Call: $callerName',
        '$phoneNumber • ${tourInterest ?? 'Travel Inquiry'}',
        details,
        payload: 'call:$phoneNumber',
      );
    } catch (e) {
      debugPrint('Error displaying incoming call notification: $e');
    }
  }

  /// Show Alert for New Chatbot / Google Ads Lead
  Future<void> showNewLeadNotification({
    required String leadName,
    required String phone,
    required String destination,
    String? source,
  }) async {
    if (kIsWeb) {
      debugPrint('🔥 New Lead: $leadName ($destination)');
      playAlertChime();
      return;
    }
    await init();
    playAlertChime();
    HapticFeedback.mediumImpact();

    final androidDetails = AndroidNotificationDetails(
      channelLeadsId,
      channelLeadsName,
      channelDescription: channelLeadsDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        'Destination: $destination\nPhone: $phone\nAttribution: ${source ?? 'Google Ads / Web Chatbot'}',
        contentTitle: '🔥 Hot Lead: $leadName ($destination)',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🔥 Hot Lead: $leadName',
        'Inquired for $destination ($phone)',
        details,
        payload: 'lead:$phone',
      );
    } catch (e) {
      debugPrint('Error displaying lead notification: $e');
    }
  }

  /// Sound Effects: Ringtone loop for incoming calls
  Future<void> playRingtone() async {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      if (kIsWeb) {
        triggerWebSound('ringtone');
        return;
      }
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(
        UrlSource('https://cdn.freesound.org/previews/219/219110_40828-lq.mp3'),
      );
    } catch (e) {
      debugPrint('Fallback to system sound: $e');
      SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Stop ringtone
  Future<void> stopRingtone() async {
    try {
      if (kIsWeb) return;
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Sound Effects: Short Chime for new leads & notifications
  Future<void> playAlertChime() async {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
      if (kIsWeb) {
        triggerWebSound('chime');
        return;
      }
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.play(
        UrlSource('https://cdn.freesound.org/previews/536/536108_11529188-lq.mp3'),
      );
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Sound Effects: Success Chime for payment links & quote generation
  Future<void> playSuccessChime() async {
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      if (kIsWeb) {
        triggerWebSound('success');
        return;
      }
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.play(
        UrlSource('https://cdn.freesound.org/previews/320/320655_5260872-lq.mp3'),
      );
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Haptic vibration pattern for calls
  void vibrateCallPattern() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 600), () => HapticFeedback.heavyImpact());
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
