import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycamp_app/core/storage/hive_initializer.dart';
import 'package:mycamp_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:mycamp_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mycamp_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:mycamp_app/features/home/presentation/screens/home_screen.dart';

final appLinks = AppLinks();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await HiveInitializer.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _uriSub;
  bool _isHandlingRecovery = false;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() {
    _uriSub?.cancel();
    super.dispose();
  }

  void initDeepLinks() {
    _uriSub = appLinks.uriLinkStream.listen((Uri uri) {
      // ignore: avoid_print
      print("Incoming link: $uri");

      if (_isRecoveryLink(uri)) {
        handleRecovery(uri);
      }
    });

    // Handle cold start (AppLinks < 6 doesn't include initial link in stream)
    appLinks.getInitialAppLink().then((Uri? uri) {
      if (!mounted || uri == null) return;
      // ignore: avoid_print
      print("Incoming link: $uri");

      if (_isRecoveryLink(uri)) {
        handleRecovery(uri);
      }
    });
  }

  bool _isRecoveryLink(Uri uri) {
    final asString = uri.toString();
    return uri.host == 'reset-callback' ||
        asString.contains('type=recovery') ||
        uri.queryParameters['type'] == 'recovery';
  }

  Future<void> handleRecovery(Uri uri) async {
    if (_isHandlingRecovery) return;
    _isHandlingRecovery = true;
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.getSessionFromUrl(uri);

      if (!mounted) return;
      if (response.session.accessToken.isEmpty) {
        // ignore: avoid_print
        print("Session null");
        return;
      }

      // ignore: avoid_print
      print("Recovery session received");

      void tryPush({int attempt = 0}) {
        final navigator = navigatorKey.currentState;
        if (navigator == null) {
          if (attempt >= 10) return;
          Future.delayed(const Duration(milliseconds: 50), () {
            tryPush(attempt: attempt + 1);
          });
          return;
        }
        navigator.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => tryPush());
    } catch (_) {
      if (!mounted) return;
      // ignore: avoid_print
      print("Session null");
    } finally {
      _isHandlingRecovery = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCamp',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DA0AA)),
        scaffoldBackgroundColor: const Color(0xFFF6F2FA),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) {
            return const LoginScreen();
          }

          // If user must change their password, force them to the change screen.
          final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
          if (metadata?['must_change_password'] == true) {
            return const ChangePasswordScreen();
          }

          return const HomeScreen();
        },
      ),
    );
  }
}
