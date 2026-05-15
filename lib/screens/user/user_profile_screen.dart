import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './quicker_agent_page.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  final Color primaryColor = const Color(0xffA020F0);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final width = MediaQuery.of(context).size.width;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: width * 0.055,
            right: width * 0.055,
            bottom: 110,
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 500,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final data =
                  userSnapshot.data?.data() as Map<String, dynamic>? ?? {};

              final name = data["name"] ?? "User";
              final email = data["email"] ?? user.email ?? "";
              final phone = data["phone"] ?? "";
              final balance = data["walletBalance"] ?? 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileHeader(name, email),
                  const SizedBox(height: 25),
                  _stats(user.uid),
                  const SizedBox(height: 32),
                  _walletCard(balance),
                  const SizedBox(height: 18),

                  _menuItem(
                    context,
                    Icons.person,
                    "Personal Information",
                    "Update your basic details",
                    () {
                      _showEditProfileSheet(
                        context: context,
                        uid: user.uid,
                        oldName: name,
                        oldPhone: phone,
                      );
                    },
                  ),

                  _menuItem(
                    context,
                    Icons.lock,
                    "Security",
                    "Change your password",
                    () {
                      _showChangePasswordSheet(context);
                    },
                  ),

                  _menuItem(
                    context,
                    Icons.smart_toy_outlined,
                    "Quicker Agent",
                    "Ask anything with inbuilt AI chatbot",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QuickerAgentPage(),
                        ),
                      );
                    },
                  ),

                  _menuItem(
                    context,
                    Icons.email,
                    "Email",
                    email,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Email cannot be edited here"),
                        ),
                      );
                    },
                  ),

                  _logoutButton(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(String name, String email) {
    String initials = "U";

    if (name.toString().trim().isNotEmpty) {
      final split = name.toString().trim().split(" ");
      initials = split.length >= 2
          ? "${split[0][0]}${split[1][0]}".toUpperCase()
          : split[0][0].toUpperCase();
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 33,
          backgroundColor: primaryColor,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: primaryColor,
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                email.isNotEmpty ? email : "No email available",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stats(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, requestSnapshot) {
        int requests = 0;
        Set experts = {};

        if (requestSnapshot.hasData) {
          requests = requestSnapshot.data!.docs.length;

          for (var doc in requestSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};

            if (data["expertId"] != null &&
                data["expertId"].toString().isNotEmpty) {
              experts.add(data["expertId"]);
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("events").snapshots(),
          builder: (context, eventSnapshot) {
            int eventsAttended = 0;

            if (eventSnapshot.hasData) {
              for (var doc in eventSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>? ?? {};

                final registeredUsers = data["registeredUsers"];

                if (registeredUsers is List) {
                  final isRegistered = registeredUsers.any((item) {
                    if (item is String) {
                      return item == uid;
                    }

                    if (item is Map) {
                      return item["userId"] == uid || item["uid"] == uid;
                    }

                    return false;
                  });

                  if (isRegistered) {
                    eventsAttended++;
                  }
                }
              }
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statBox("$requests", "Requests"),
                _statBox("${experts.length}", "Experts"),
                _statBox("$eventsAttended", "Events"),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statBox(String value, String title) {
    return Container(
      height: 78,
      width: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 7,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Color(0xff64748B))),
        ],
      ),
    );
  }

  Widget _walletCard(dynamic balance) {
    return Container(
      height: 125,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xffB347FF), Color(0xff9700FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Available Balance",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "₹$balance.00",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 40,
              width: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  "Top Up",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xffF3E8FF),
              child: Icon(icon, color: primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xff64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xff94A3B8)),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet({
    required BuildContext context,
    required String uid,
    required String oldName,
    required String oldPhone,
  }) {
    final nameController = TextEditingController(text: oldName);
    final phoneController = TextEditingController(text: oldPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Profile",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: _inputDecoration("Full Name"),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Phone Number"),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(uid)
                        .update({
                      "name": nameController.text.trim(),
                      "phone": phoneController.text.trim(),
                      "updatedAt": FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile updated")),
                    );
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Change Password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: _inputDecoration("New Password"),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: _inputDecoration("Confirm Password"),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final newPassword = passwordController.text.trim();
                    final confirmPassword = confirmController.text.trim();

                    if (newPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password must be at least 6 characters"),
                        ),
                      );
                      return;
                    }

                    if (newPassword != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match")),
                      );
                      return;
                    }

                    try {
                      await FirebaseAuth.instance.currentUser!
                          .updatePassword(newPassword);

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password updated")),
                      );
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.code == "requires-recent-login"
                                ? "Please logout and login again before changing password"
                                : e.message ?? "Password update failed",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Update Password",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xffF4F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();

          Navigator.pushNamedAndRemoveUntil(
            context,
            "/login",
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          "Logout",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}