import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 🔽 Screens
import 'screens/splash_screen.dart';
import 'screens/user_login_page.dart';
import 'screens/expert_login_page.dart';
import './screens/expert_profile_page.dart';

// 🔽 User module screens
import 'screens/user_main_page.dart';
import 'screens/user/user_request_screen.dart';
import 'screens/user/user_notification.dart';
import 'screens/user/user_profile_screen.dart';

// 🔽 Expert module screens
// import './screens/expert/expert_home_screen.dart';
import 'screens/expert/expert_profile_screen.dart';
import './screens/expert/expert_notification.dart';
import './screens/expert/expert_messages_screen.dart';
import 'screens/expert/expert_coins_page.dart';
import 'screens/expert/expert_requests_screen.dart';

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

      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),

      // 🔥 ROUTES
      routes: {
        // Auth
        "/login": (context) => const UserLogin(),
        "/expertLogin": (context) => const ExpertLogin(),

        // User
        "/userMain": (context) => const UserMainScreen(),
        "/requests": (context) => const UserRequestsScreen(),
        "/notifications": (context) => const UserNotificationsScreen(),
        "/profile": (context) => const UserProfileScreen(),

        // Expert
        "/expertCoins": (context) => const ExpertCoinsPage(),
        "/expertHome": (context) => const ExpertProfilePage(),
        "/expertProfile": (context) => const ExpertProfileScreen(),
        "/expertNotifications": (context) =>
            const ExpertNotificationsPage(),
        "/expertChat": (context) => const ExpertMessagesScreen(),
        "/expertRequests": (context) => const ExpertRequestsScreen(),
        "/coinEarning": (context) => const ExpertCoinsPage(),
      },
    );
  }
}