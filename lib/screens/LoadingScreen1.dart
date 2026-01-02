import 'package:flutter/material.dart';
import 'LoginOrSigup.dart';   // <-- import your next screen

class LoadingScreen1 extends StatefulWidget {
  const LoadingScreen1({super.key});

  @override
  LoadingScreen1State createState() => LoadingScreen1State();
}

class LoadingScreen1State extends State<LoadingScreen1> {

  @override
  void initState() {
    super.initState();

    // Auto navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginOrSigup()),
      );
    });
  }

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
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1, -1),
                      end: Alignment(-1, 1),
                      colors: [
                        Color(0xFF2C3BAC),
                        Color(0xFF150C4C),
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 140),
                        const Text(
                          "WAY2COLLEGE",
                          style: TextStyle(color: Colors.white, fontSize: 40),
                        ),
                        const SizedBox(height: 80),
                        const Icon(Icons.directions_bus,
                            size: 100, color: Colors.white),
                        const SizedBox(height: 120),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 74, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF017282),
                            borderRadius: BorderRadius.circular(37),
                          ),
                          child: const Text(
                            "GET STARTED",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
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
