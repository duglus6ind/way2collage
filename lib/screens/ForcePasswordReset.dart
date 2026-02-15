import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/utils/PasswordUtils.dart';

class ForcePasswordResetScreen extends StatefulWidget {
  final String userId;
  final String role;

  const ForcePasswordResetScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<ForcePasswordResetScreen> createState() =>
      _ForcePasswordResetScreenState();
}

class _ForcePasswordResetScreenState extends State<ForcePasswordResetScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _resetPassword() async {
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      _showMessage("Please fill all fields");
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      _showMessage("Passwords do not match");
      return;
    }

    final hashed = hashPassword(_passwordController.text);

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .update({'Password': hashed, 'ForcePasswordReset': false});

    Navigator.pop(context, true);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: size.height * 0.55,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0A7A55),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            child: Container(
              height: size.height * 0.45,
              width: size.width,
              color: Colors.white,
            ),
          ),

          Center(
            child: Container(
              width: size.width * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EEEE),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Reset Password",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "You must reset your password before continuing",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  _passwordField(
                    controller: _passwordController,
                    hint: "New Password",
                    obscure: _obscure1,
                    toggle: () {
                      setState(() {
                        _obscure1 = !_obscure1;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  _passwordField(
                    controller: _confirmController,
                    hint: "Confirm Password",
                    obscure: _obscure2,
                    toggle: () {
                      setState(() {
                        _obscure2 = !_obscure2;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: _resetPassword,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3BE37A),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
