import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/UserLogin.dart';

class LoadingScreen1 extends StatefulWidget {
  const LoadingScreen1({super.key});

  @override
  LoadingScreen1State createState() => LoadingScreen1State();
}

class LoadingScreen1State extends State<LoadingScreen1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xBFEEEAEA),
          child: Column(
            children: [
              const Spacer(flex: 2),

              //  APP TITLE
              const Text(
                "WAY2COLLEGE",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(flex: 2),

              //  CENTER IMAGE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 238,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/bus.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              //  GET STARTED BUTTON
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const UserLogin()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 86,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF095B41),
                    borderRadius: BorderRadius.circular(37),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(5, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    "GET STARTED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
