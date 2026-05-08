import 'package:flutter/material.dart';
import './user/user_home_screen.dart';
import './user/user_chat_screen.dart';
import './user/user_request_screen.dart';
import './user/user_profile_screen.dart';
import './ask_question.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int selectedIndex = 0;
  final Color primaryColor = const Color(0xffA020F0);

  final pages = const [
    UserHomeScreen(),
    UserChatScreen(),
    UserRequestsScreen(),
    UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],

      floatingActionButton: Container(
        height: 62,
        width: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add_circle_outline,
              color: Colors.white, size: 34),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AskQuestionScreen(),
              ),
            );
          },
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        color: Colors.white,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(Icons.home_outlined, "Home", 0),
              navItem(Icons.chat_bubble_outline, "Messages", 1),
              const SizedBox(width: 45),
              navItem(Icons.description_outlined, "Requests", 2),
              navItem(Icons.account_circle_outlined, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String title, int index) {
    final selected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? primaryColor : const Color(0xff94A3B8),
            size: 25,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: selected ? primaryColor : const Color(0xff94A3B8),
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}