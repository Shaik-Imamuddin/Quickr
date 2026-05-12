import 'package:flutter/material.dart';
import './expert/expert_home_screen.dart';
import './expert/expert_messages_screen.dart';
import './expert/expert_profile_screen.dart';
import './expert/expert_requests_screen.dart';

class ExpertProfilePage extends StatefulWidget {
  const ExpertProfilePage({super.key});

  @override
  State<ExpertProfilePage> createState() => _ExpertMainScreenState();
}

class _ExpertMainScreenState extends State<ExpertProfilePage> {
  int selectedIndex = 0;
  final Color primaryColor = const Color(0xffF5A400);

  final pages = const [
    ExpertHomeScreen(),
    ExpertMessagesScreen(),
    ExpertRequestsScreen(),
    ExpertProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],

      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, "/coinEarning");
        },
        child: Container(
          height: 62,
          width: 62,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.work_history,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 12,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
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
      onTap: () => setState(() => selectedIndex = index),
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