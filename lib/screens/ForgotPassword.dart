import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/utils/PasswordUtils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _showResetFields = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _verifyUser() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();

    if (!doc.exists) {
      _showMessage("User not found");
      return;
    }

    final data = doc.data()!;
    if (data['Active'] == false) {
      _showMessage("Account is deactivated. Contact Bus Secretary.");
      return;
    }

    setState(() {
      _showResetFields = true;
    });
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      _showMessage("Please fill all fields");
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      _showMessage("Passwords do not match");
      return;
    }

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(_userIdController.text.trim())
        .update({
          'Password': hashPassword(_passwordController.text),
          'ForcePasswordReset': false,
          'FailedAttempts': 0,
          'FirstFailedAt': null,
          'LockUntil': null,
        });

    _showMessage("Password reset successful");
    Navigator.pop(context);
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
            color: const Color(0xFF0A7A55),
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
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: size.width * 0.85,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  margin: const EdgeInsets.only(bottom: 32),
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
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _inputField(
                        hint: "User ID",
                        controller: _userIdController,
                      ),

                      if (_showResetFields) ...[
                        const SizedBox(height: 18),

                        _inputField(
                          hint: "New Password",
                          controller: _passwordController,
                          obscure: _obscure1,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure1
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscure1 = !_obscure1;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 18),

                        _inputField(
                          hint: "Confirm Password",
                          controller: _confirmController,
                          obscure: _obscure2,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure2
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscure2 = !_obscure2;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: _showResetFields ? _resetPassword : _verifyUser,
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
                    child: Icon(
                      _showResetFields ? Icons.check : Icons.arrow_forward,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
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
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
