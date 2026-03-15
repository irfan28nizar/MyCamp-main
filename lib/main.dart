import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycamp_app/core/storage/hive_initializer.dart';
import 'package:mycamp_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:mycamp_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mycamp_app/features/home/presentation/screens/home_screen.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _getHomeScreen() {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) return const LoginScreen();

    // If user must change their password, force them to the change screen.
    final metadata = client.auth.currentUser?.userMetadata;
    if (metadata?['must_change_password'] == true) {
      return const ChangePasswordScreen();
    }

    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCamp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DA0AA)),
        scaffoldBackgroundColor: const Color(0xFFF6F2FA),
      ),
      home: _getHomeScreen(),
    );
  }
}
