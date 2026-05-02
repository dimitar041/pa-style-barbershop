import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/client_main_screen.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } else {
    await Firebase.initializeApp();
  }
}

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

void main() {
  runApp(const PaStyleApp());
}

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await _localNotifications.initialize(settings: initSettings);

  const channel = AndroidNotificationChannel(
    'appointments',
    'PA Style известия',
    description: 'Известия за запазени часове',
    importance: Importance.high,
  );

  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class PaStyleApp extends StatelessWidget {
  const PaStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PA Style Barbershop',
      locale: const Locale('bg', 'BG'),
      supportedLocales: const [Locale('bg', 'BG')],
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.build(),
      themeMode: ThemeMode.dark,
      home: const _FirebaseInitGate(),
    );
  }
}

class _FirebaseInitGate extends StatefulWidget {
  const _FirebaseInitGate();

  @override
  State<_FirebaseInitGate> createState() => _FirebaseInitGateState();
}

class _FirebaseInitGateState extends State<_FirebaseInitGate> {
  Future<bool>? _initFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFuture = _bootstrap();
  }

  Future<bool> _bootstrap() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      if (kIsWeb) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } else {
        await Firebase.initializeApp();
      }
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        await _initLocalNotifications();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snap.data == true) return const _AuthGate();

        return Scaffold(
          appBar: AppBar(title: const Text('Firebase конфигурация')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text(
                  'Приложението е включено с Firebase, но липсва web конфигурация.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'За да стартираш на Chrome/WEB, трябва да генерираш `firebase_options.dart` чрез `flutterfire configure`.',
                ),
                const SizedBox(height: 12),
                if (_error != null) Text('Грешка: $_error'),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => setState(() {
                    _error = null;
                    _initFuture = _bootstrap();
                  }),
                  child: const Text('Опитай отново'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _AppRole { client, admin }

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;
  String? _pushTokenInitForUid;

  Future<void> _ensurePushToken(String uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore.collection('profiles').doc(uid).set(
      {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  _AppRole? _roleFromString(String? role) {
    switch (role) {
      case 'client':
        return _AppRole.client;
      case 'admin':
      case 'barber':
        return _AppRole.admin;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final nav = Navigator.of(context, rootNavigator: true);
            if (nav.canPop()) nav.popUntil((route) => route.isFirst);
          });
          return const LoginScreen();
        }

        if (_pushTokenInitForUid != user.uid) {
          _pushTokenInitForUid = user.uid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_ensurePushToken(user.uid));
          });
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _firestore.collection('profiles').doc(user.uid).get(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState != ConnectionState.done) {
              return const ClientMainScreen();
            }

            final data = profileSnap.data?.data();
            final role = _roleFromString(data?['role'] as String?);

            if (role == null) return const ClientMainScreen();

            switch (role) {
              case _AppRole.client:
                return const ClientMainScreen();
              case _AppRole.admin:
                return const AdminMainScreen();
            }
          },
        );
      },
    );
  }
}
