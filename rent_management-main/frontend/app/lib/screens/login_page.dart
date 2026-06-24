import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  bool isLoading = false;
  String? topMessage;
  bool isError = false;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    animationController.dispose();
    super.dispose();
  }

  void showMessage(String msg, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      topMessage = msg;
      isError = error;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => topMessage = null);
    });
  }

  Future<void> loginUser() async {
    if (isLoading) return;
    final identifier = emailController.text.trim();

    if (identifier.isEmpty) {
      showMessage("Please enter email or phone", error: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Calls the AuthService.login method we defined
      final res = await AuthService.login(identifier);

      if (!mounted) return;

      if (res["success"] == true) {
        final user = res["user"];
        showMessage("Login Successful");

        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            '/dashboard',
            arguments: {
              "role": user["role"] ?? "tenant",
              "userName": user["name"] ?? "User",
              "renterId": user["id"]?.toString() ?? "",
            },
          );
        });
      } else {
        showMessage(res["error"] ?? "Login failed", error: true);
      }
    } catch (e) {
      showMessage("Something went wrong", error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1D4ED8)],
          ),
        ),
        child: Stack(
          children: [
            // Background Circles (Kept for design consistency)
            Positioned(top: -120, left: -100, child: Container(height: 260, width: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.12)))),
            Positioned(bottom: -100, right: -80, child: Container(height: 220, width: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: animationController,
                  child: Container(
                    width: 430,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 30, offset: const Offset(0, 12))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // LOGO (Kept)
                        ClipOval(child: Image.asset('assets/images/logo.png', height: 95, width: 95, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.home_work_rounded, size: 45, color: Colors.white))),
                        const SizedBox(height: 24),
                        const Text("Rent Management", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const Text("Direct Access", style: TextStyle(color: Colors.white70, fontSize: 15)),
                        const SizedBox(height: 28),

                        // MESSAGE BOX (Kept)
                        if (topMessage != null) ...[
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                             margin: const EdgeInsets.only(bottom: 20),
                             decoration: BoxDecoration(color: (isError ? Colors.red : Colors.green).withOpacity(0.14), borderRadius: BorderRadius.circular(18), border: Border.all(color: isError ? Colors.redAccent : Colors.greenAccent)),
                             child: Row(children: [Icon(isError ? Icons.error_outline : Icons.check_circle, color: isError ? Colors.redAccent : Colors.greenAccent), const SizedBox(width: 12), Expanded(child: Text(topMessage!, style: TextStyle(color: isError ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.w600)))]),
                           )
                        ],

                        // INPUT FIELD
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: inputDecoration(hint: "Enter Email or Phone", icon: Icons.person_rounded),
                        ),
                        const SizedBox(height: 30),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : loginUser,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1D4ED8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                            child: isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.login_rounded), SizedBox(width: 10), Text("Login", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    );
  }
}