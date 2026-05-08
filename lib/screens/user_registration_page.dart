import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_login_page.dart';

class UserRegistrationPage extends StatefulWidget {
  const UserRegistrationPage({super.key});

  @override
  State<UserRegistrationPage> createState() => _UserRegistrationPageState();
}

class _UserRegistrationPageState extends State<UserRegistrationPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  final Color primaryColor = const Color(0xFF8B6BEF);

  Future<void> createUserAccount() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        "uid": userCredential.user!.uid,
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "role": "user",
        "provider": "email",
        "createdAt": FieldValue.serverTimestamp(),
      });

      nameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User account created successfully")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => isLoading = true);

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        "uid": userCredential.user!.uid,
        "name": userCredential.user!.displayName ?? "",
        "email": userCredential.user!.email ?? "",
        "phone": userCredential.user!.phoneNumber ?? "",
        "role": "user",
        "provider": "google",
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In successful")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? hidePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => hidePassword = !hidePassword);
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget socialButton({
    required String text,
    required String logo,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(logo, height: 22),
              const SizedBox(width: 15),
              Text(text, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 350,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F0FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(45),
                  bottomRight: Radius.circular(45),
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 15,
                      left: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 95,
                      left: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "User Registration",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Create your account to get help\nfrom verified experts instantly.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: 
                      Image.asset(
                        "assets/images/user-2.png",
                        height: screenHeight * 0.18,
                        fit: BoxFit.contain,
                      )
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                children: [
                  inputField(
                    controller: nameController,
                    hint: "User Name",
                    icon: Icons.person_outline,
                  ),
                  inputField(
                    controller: emailController,
                    hint: "Email Address",
                    icon: Icons.email_outlined,
                  ),
                  inputField(
                    controller: phoneController,
                    hint: "Phone Number",
                    icon: Icons.phone_outlined,
                  ),
                  inputField(
                    controller: passwordController,
                    hint: "Create Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),

                  const SizedBox(height: 3),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "We never share your data with anyone",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: 300,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : createUserAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 40),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserLogin(),
                        ),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: Color(0xFF7B61FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "or continue with",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      socialButton(
                        text: "Google",
                        logo: "assets/images/google.png",
                        onTap: signInWithGoogle,
                      ),
                      const SizedBox(width: 18),
                      socialButton(
                        text: "Apple",
                        logo: "assets/images/apple.png",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Apple Sign-In coming soon"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "By signing up, you agree to our\n",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: "Terms of Service",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy.",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}