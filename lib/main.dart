import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 🔽 Screens
import 'screens/splash_screen.dart';
import 'screens/user_login_page.dart';

// 🔽 User module screens
import 'screens/user_main_page.dart';
import 'screens/user/user_request_screen.dart';
import 'screens/user/user_notification.dart';
import 'screens/user/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔥 Initial screen
      home: const SplashScreen(),

      // 🔥 Global theme (optional but clean UI)
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),

      // 🔥 ROUTES
      routes: {
        "/login": (context) => const UserLogin(),
        "/userMain": (context) => const UserMainScreen(),
        "/requests": (context) => const UserRequestsScreen(),
        "/notifications": (context) => const UserNotificationsScreen(),
        "/profile": (context) => const UserProfileScreen(),
      },
    );
  }
}