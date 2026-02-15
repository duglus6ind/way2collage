import 'package:flutter/material.dart';
class UserRegister extends StatefulWidget {
  const UserRegister({super.key});

  @override
  State<UserRegister> createState() => _UserRegisterState();
}

class _UserRegisterState extends State<UserRegister> {
  String username = '';
  String password = '';
  String confirmPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔙 Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 60),

              // 🔵 Blue rounded container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF174E78), // dark blue
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    // USER NAME
                    _buildTextField(
                      hint: "User Name",
                      onChanged: (v) => username = v,
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD
                    _buildTextField(
                      hint: "Password",
                      obscure: true,
                      onChanged: (v) => password = v,
                    ),

                    const SizedBox(height: 16),

                    // CONFIRM PASSWORD
                    _buildTextField(
                      hint: "Confirm Password",
                      obscure: true,
                      onChanged: (v) => confirmPassword = v,
                    ),

                    const SizedBox(height: 30),

                    // REGISTER BUTTON
                    InkWell(
                      onTap: () {
                        if (password == confirmPassword) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginOrSigup(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match"),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "REGISTER",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔧 Reusable TextField widget
  Widget _buildTextField({
    required String hint,
    bool obscure = false,
    required Function(String) onChanged,
  }) {
    return TextField(
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
