import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpertProfileScreen extends StatefulWidget {
  const ExpertProfileScreen({super.key});

  @override
  State<ExpertProfileScreen> createState() => _ExpertProfileScreenState();
}

class _ExpertProfileScreenState extends State<ExpertProfileScreen> {
  final Color primaryColor = const Color(0xffF5A400);
  final Color darkText = const Color(0xff1E293B);
  final Color lightText = const Color(0xff64748B);
  final Color bgColor = const Color(0xffF8FAFC);

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(
      context,
      "/expertLogin",
      (route) => false,
    );
  }

  void openProfileEditSheet({
    required String uid,
    required String name,
    required String phone,
  }) {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);

    _showPremiumSheet(
      title: "Edit Profile Details",
      subtitle: "Update your basic expert information",
      child: Column(
        children: [
          _premiumTextField(
            controller: nameController,
            label: "Full Name",
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          _premiumTextField(
            controller: phoneController,
            label: "Phone Number",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      onSave: () async {
        await FirebaseFirestore.instance.collection("experts").doc(uid).update({
          "name": nameController.text.trim(),
          "phone": phoneController.text.trim(),
          "updatedAt": FieldValue.serverTimestamp(),
        });

        if (mounted) Navigator.pop(context);
      },
    );
  }

  void openAboutEditSheet({
    required String uid,
    required String about,
  }) {
    final aboutController = TextEditingController(text: about);

    _showPremiumSheet(
      title: "Edit About Me",
      subtitle: "Tell users why they should choose you",
      child: _premiumTextField(
        controller: aboutController,
        label: "About Me",
        icon: Icons.description_outlined,
        maxLines: 6,
      ),
      onSave: () async {
        await FirebaseFirestore.instance.collection("experts").doc(uid).update({
          "about": aboutController.text.trim(),
          "updatedAt": FieldValue.serverTimestamp(),
        });

        if (mounted) Navigator.pop(context);
      },
    );
  }

  void openExpertiseEditSheet({
    required String uid,
    required List<String> expertise,
  }) {
    final expertiseController = TextEditingController(
      text: expertise.join(", "),
    );

    _showPremiumSheet(
      title: "Edit Expertise",
      subtitle: "Add skills separated by comma",
      child: _premiumTextField(
        controller: expertiseController,
        label: "Example: Java, Spring Boot, Firebase",
        icon: Icons.psychology_outlined,
        maxLines: 3,
      ),
      onSave: () async {
        final skills = expertiseController.text
            .split(",")
            .map((skill) => skill.trim())
            .where((skill) => skill.isNotEmpty)
            .toList();

        await FirebaseFirestore.instance.collection("experts").doc(uid).update({
          "expertise": skills,
          "updatedAt": FieldValue.serverTimestamp(),
        });

        if (mounted) Navigator.pop(context);
      },
    );
  }

  void openChangePasswordSheet() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    _showPremiumSheet(
      title: "Change Password",
      subtitle: "Update your expert account password",
      child: Column(
        children: [
          _premiumTextField(
            controller: passwordController,
            label: "New Password",
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 14),
          _premiumTextField(
            controller: confirmController,
            label: "Confirm Password",
            icon: Icons.lock_reset,
            obscureText: true,
          ),
        ],
      ),
      onSave: () async {
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
          await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);

          if (mounted) Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password updated successfully")),
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
    );
  }

  void openPrivacySheet({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    bool profileVisible = data["profileVisible"] ?? true;
    bool availabilityVisible = data["availabilityVisible"] ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Privacy Settings",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    value: profileVisible,
                    activeColor: primaryColor,
                    title: const Text("Profile Visible"),
                    subtitle: const Text("Allow users to view your profile"),
                    onChanged: (value) {
                      setModalState(() {
                        profileVisible = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    value: availabilityVisible,
                    activeColor: primaryColor,
                    title: const Text("Availability Visible"),
                    subtitle: const Text("Show your online/offline status"),
                    onChanged: (value) {
                      setModalState(() {
                        availabilityVisible = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
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
                            .collection("experts")
                            .doc(uid)
                            .update({
                          "profileVisible": profileVisible,
                          "availabilityVisible": availabilityVisible,
                          "updatedAt": FieldValue.serverTimestamp(),
                        });

                        if (mounted) Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Privacy settings updated"),
                          ),
                        );
                      },
                      child: const Text(
                        "Save Privacy Settings",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPremiumSheet({
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xffCBD5E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF4CC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.edit, color: primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 13, color: lightText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                child,
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Color(0xffE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: lightText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onSave,
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _premiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryColor),
        labelText: label,
        filled: true,
        fillColor: const Color(0xffF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryColor, width: 1.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Expert not logged in")),
      );
    }

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("experts")
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

            final name = data["name"] ?? "Expert";
            final email = data["email"] ?? user.email ?? "";
            final phone = data["phone"] ?? "";
            final about = data["about"] ??
                "I am a software developer who loves helping others solve technical problems.";
            final expertise = List<String>.from(
              data["expertise"] ?? ["Java", "Spring Boot"],
            );
            final isOnline = data["isOnline"] ?? false;
            final coins = data["coins"] ?? 0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                width * 0.055,
                16,
                width * 0.055,
                110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileCard(
                    uid: user.uid,
                    name: name,
                    email: email,
                    phone: phone,
                    isOnline: isOnline,
                  ),
                  const SizedBox(height: 22),
                  _stats(user.uid),
                  const SizedBox(height: 22),
                  _premiumSection(
                    title: "About Me",
                    icon: Icons.description_outlined,
                    onEdit: () {
                      openAboutEditSheet(uid: user.uid, about: about);
                    },
                    child: Text(
                      about,
                      style: TextStyle(
                        color: lightText,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _premiumSection(
                    title: "My Expertise",
                    icon: Icons.psychology_outlined,
                    onEdit: () {
                      openExpertiseEditSheet(
                        uid: user.uid,
                        expertise: expertise,
                      );
                    },
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: expertise.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF4CC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _menuItem(
                    icon: Icons.lock_outline,
                    title: "Security",
                    subtitle: "Change your password",
                    onTap: openChangePasswordSheet,
                  ),
                  _menuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Settings",
                    subtitle: "Manage your profile visibility",
                    onTap: () {
                      openPrivacySheet(uid: user.uid, data: data);
                    },
                  ),
                  _menuItem(
                    icon: Icons.bar_chart_outlined,
                    title: "My Activity",
                    subtitle: "View accepted and completed requests",
                    onTap: () {
                      Navigator.pushNamed(context, "/expertRequests");
                    },
                  ),
                  _premiumSection(
                    title: "Account Information",
                    icon: Icons.account_circle_outlined,
                    showEdit: false,
                    child: Column(
                      children: [
                        _info(Icons.email_outlined, "Email Address", email),
                        _info(Icons.phone_outlined, "Phone Number", phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _logoutButton(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _profileCard({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required bool isOnline,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: primaryColor,
            child: const Text("👨‍💻", style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: primaryColor,
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  isOnline ? "● Online" : "● Offline",
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: lightText, fontSize: 13),
                ),
                Text(
                  phone,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: lightText, fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              openProfileEditSheet(
                uid: uid,
                name: name,
                phone: phone,
              );
            },
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xffFFF4CC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.edit, color: primaryColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coinsCard(dynamic coins) {
    return Container(
      height: 112,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffFFB800), Color(0xffFF5A00)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xffffd46b),
            child: Icon(Icons.monetization_on, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Available Coins",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  "$coins Coins",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/expertCoins");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                "View",
                style: TextStyle(
                  color: Color(0xffFF5A00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffE5E7EB)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xffFFF4CC),
              child: Icon(icon, color: primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: darkText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: lightText,
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

  Widget _premiumSection({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onEdit,
    bool showEdit = true,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xffFFF4CC),
                child: Icon(icon, color: primaryColor, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ),
              if (showEdit)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF4CC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Edit",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _stats(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("expertId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        int today = 0;
        int completed = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          today = docs.length;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            if (data["status"] == "Completed") {
              completed++;
            }
          }
        }

        return Row(
          children: [
            Expanded(child: _statBox("💰", "\$${today * 100}+", "Today")),
            const SizedBox(width: 6),
            Expanded(child: _statBox("💵", "\$${completed * 100}+", "This Week")),
            const SizedBox(width: 6),
            Expanded(child: _statBox("⭐", "4.9", "Rating")),
            const SizedBox(width: 6),
            Expanded(child: _statBox("📊", "\$${completed * 100}", "Earned")),
          ],
        );
      },
    );
    }

  Widget _statBox(String emoji, String value, String title) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: lightText,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff94A3B8), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: darkText, fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: lightText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffEF4444),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: () => logout(context),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          "Logout",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}