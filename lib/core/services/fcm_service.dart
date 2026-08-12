import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firebase_constants.dart';
import '../constants/roles.dart';

/// Handler untuk pesan FCM saat app di background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Tampilkan notifikasi lokal saat background
  await FCMService._showLocalNotification(message);
}

class FCMService {
  FCMService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi FCM — dipanggil di main()
  static Future<void> initialize() async {
    // Setup local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Minta izin notifikasi
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handler saat app FOREGROUND
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Subscribe ke topic global
    await _fcm.subscribeToTopic(FirebaseConstants.topicAllUsers);

    // Simpan FCM token ke Firestore
    await _saveTokenToFirestore();

    // Refresh token listener
    _fcm.onTokenRefresh.listen(_updateToken);
  }

  /// Subscribe ke topic berdasarkan role pengguna
  static Future<void> subscribeByRole(String role) async {
    final topicMap = {
      AppRoles.siswa:     FirebaseConstants.topicSiswa,
      AppRoles.guruMapel: FirebaseConstants.topicGuru,
      AppRoles.waliKelas: FirebaseConstants.topicWali,
      AppRoles.guruBK:    FirebaseConstants.topicBK,
      AppRoles.guruPiket: FirebaseConstants.topicPiket,
    };
    final topic = topicMap[role];
    if (topic != null) await _fcm.subscribeToTopic(topic);
  }

  /// Kirim notifikasi lokal
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'edutech_smk_channel',
      'EduTech SMK',
      channelDescription: 'Notifikasi dari aplikasi EduTech SMK',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Navigasi berdasarkan payload notifikasi
  }

  static Future<void> _saveTokenToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.users)
        .doc(uid)
        .update({FirebaseConstants.fieldFcmToken: token});
  }

  static Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.users)
        .doc(uid)
        .update({FirebaseConstants.fieldFcmToken: token});
  }

  /// Ambil FCM token perangkat saat ini
  static Future<String?> getToken() => _fcm.getToken();
}
