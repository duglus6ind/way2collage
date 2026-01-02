import 'package:flutter/material.dart';
import 'LoginOrSigup.dart';

class UserRegister extends StatefulWidget {
  const UserRegister({super.key});

  @override
  UserRegisterState createState() => UserRegisterState();
}

class UserRegisterState extends State<UserRegister> {
  String textField1 = '';
  String textField2 = '';
  String textField3 = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              TextField(
                decoration: const InputDecoration(hintText: "User Name"),
                onChanged: (v) => textField1 = v,
              ),
              TextField(
                decoration: const InputDecoration(hintText: "Password"),
                obscureText: true,
                onChanged: (v) => textField2 = v,
              ),
              TextField(
                decoration: const InputDecoration(hintText: "Confirm Password"),
                obscureText: true,
                onChanged: (v) => textField3 = v,
              ),

              const SizedBox(height: 20),

              InkWell(
                onTap: () {
                  if (textField2 == textField3) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginOrSigup()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Passwords do not match")),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "REGISTER",
                    style: TextStyle(color: Colors.white, fontSize: 18),
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
