import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firebase_constants.dart';
import '../constants/roles.dart';

/// Handler untuk pesan FCM saat app di background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FCMService._showLocalNotification(message);
}

class FCMService {
  FCMService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi FCM — dipanggil di main() (skip di web)
  static Future<void> initialize() async {
    if (kIsWeb) return; // FCM lokal tidak support web

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

    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) => _showLocalNotification(message));

    await _subscribeToTopicSafe(FirebaseConstants.topicAllUsers);
    await _saveTokenToFirestore();
    _fcm.onTokenRefresh.listen(_updateToken);
  }

  /// Subscribe ke topic berdasarkan role — aman untuk web (skip)
  static Future<void> subscribeByRole(String role) async {
    if (kIsWeb) return; // subscribeToTopic tidak support di web
    final topicMap = {
      AppRoles.siswa:     FirebaseConstants.topicSiswa,
      AppRoles.guruMapel: FirebaseConstants.topicGuru,
      AppRoles.waliKelas: FirebaseConstants.topicWali,
      AppRoles.guruBK:    FirebaseConstants.topicBK,
      AppRoles.guruPiket: FirebaseConstants.topicPiket,
    };
    final topic = topicMap[role];
    if (topic != null) await _subscribeToTopicSafe(topic);
  }

  static Future<void> _subscribeToTopicSafe(String topic) async {
    if (kIsWeb) return;
    try {
      await _fcm.subscribeToTopic(topic);
    } catch (_) {}
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;
    const androidDetails = AndroidNotificationDetails(
      'edutech_smk_channel', 'EduTech SMK',
      channelDescription: 'Notifikasi dari aplikasi EduTech SMK',
      importance: Importance.high, priority: Priority.high,
    );
    await _localNotif.show(
      notification.hashCode, notification.title, notification.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {}

  static Future<void> _saveTokenToFirestore() async {
    if (kIsWeb) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.users).doc(uid)
        .update({FirebaseConstants.fieldFcmToken: token});
  }

  static Future<void> _updateToken(String token) async {
    if (kIsWeb) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.users).doc(uid)
        .update({FirebaseConstants.fieldFcmToken: token});
  }

  static Future<String?> getToken() => _fcm.getToken();
}
