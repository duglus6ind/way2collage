import 'package:bus_tracker/screens/UserLogin.dart';
import 'package:flutter/material.dart';
import 'UserLogin.dart';
import 'SignUpFirstInterface.dart';

class LoginOrSigup extends StatefulWidget {
  const LoginOrSigup({super.key});

  @override
  LoginOrSigupState createState() => LoginOrSigupState();
}

class LoginOrSigupState extends State<LoginOrSigup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // LOGIN BUTTON
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserLogin()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80, vertical: 30),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Colors.white,
                          ),
                          child: const Text(
                            "LOGIN",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // SIGN UP TEXT
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpFirstInterface()),
                          );
                        },
                        child: const Text(
                          "New user? Sign up",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
