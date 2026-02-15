import 'package:bus_tracker/screens/UserLogin.dart';
import 'package:bus_tracker/screens/UserRegister.dart';
import 'package:flutter/material.dart';

class LoginOrSigup extends StatefulWidget {
  const LoginOrSigup({super.key});

  @override
  LoginOrSigupState createState() => LoginOrSigupState();
}

class LoginOrSigupState extends State<LoginOrSigup> {
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF164D77),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // 👈 important
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LOGIN BUTTON
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserLogin()),
                      );
                    },
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 80,
                        vertical: 30,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: Colors.white,
                      ),
                      child: const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // SIGN UP TEXT
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserRegister()),
                      );
                    },
                    child: const Text(
                      "New user? Sign up",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
