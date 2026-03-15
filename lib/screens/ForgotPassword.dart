import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/utils/PasswordUtils.dart';
import 'package:bus_tracker/services/email_service.dart';
import 'dart:math';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  int _currentStage = 0; // 0: Email, 1: OTP, 2: Reset Password
  String _generatedOtp = "";
  String _targetUserId = "";
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;

  void _nextStage() {
    setState(() {
      _currentStage++;
    });
  }

  Future<void> _verifyEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter your email");
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('Users')
        .where('Email', isEqualTo: email)
        .get();

    if (query.docs.isEmpty) {
      _showMessage("No user found with this email");
      return;
    }

    if (query.docs.length > 1) {
      _showMessage("Multiple users found. Contact administrator.");
      return;
    }

    final userDoc = query.docs.first;
    if (userDoc['Active'] == false) {
      _showMessage("Account is deactivated. Contact Bus Secretary.");
      return;
    }

    _targetUserId = userDoc.id;
    _generatedOtp = (Random().nextInt(900000) + 100000).toString();

    // REAL EMAIL SENDING
    await _sendEmailOtp(email, _generatedOtp);
  }

  Future<void> _sendEmailOtp(String email, String otp) async {
    setState(() => _isLoading = true);
    
    final success = await EmailService.sendOTP(email, otp);
    
    setState(() => _isLoading = false);

    if (success) {
      _showMessage("OTP sent to $email");
      _nextStage();
    } else {
      _showMessage("Failed to send email. Please try again.");
    }
  }

  void _verifyOtp() {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp == _generatedOtp) {
      _nextStage();
    } else {
      _showMessage("Invalid OTP");
    }
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
        .doc(_targetUserId)
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

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_currentStage == 0) // EMAIL STAGE
                        _inputField(
                          hint: "Email ID",
                          controller: _emailController,
                        ),

                      if (_currentStage == 1) // OTP STAGE
                        _inputField(
                          hint: "Enter 6-Digit OTP",
                          controller: _otpController,
                        ),

                      if (_currentStage == 2) ...[
                        // RESET PASSWORD STAGE
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
                  onTap: _isLoading
                      ? null
                      : () {
                          if (_currentStage == 0) {
                            _verifyEmail();
                          } else if (_currentStage == 1) {
                            _verifyOtp();
                          } else {
                            _resetPassword();
                          }
                        },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLoading ? Colors.grey : const Color(0xFF3BE37A),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            _currentStage == 2 ? Icons.check : Icons.arrow_forward,
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
