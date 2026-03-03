import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_tracker/screens/UserLogin.dart';
import 'package:bus_tracker/screens/BusSecretaryDashboard.dart';
import 'package:bus_tracker/screens/DriverDashboard.dart';
import 'package:bus_tracker/screens/StudentDashboard.dart';
import 'package:bus_tracker/screens/BusAttendantDashboard.dart';
import 'package:bus_tracker/services/notification_service.dart';

class LoadingScreen1 extends StatefulWidget {
  const LoadingScreen1({super.key});

  @override
  LoadingScreen1State createState() => LoadingScreen1State();
}

class LoadingScreen1State extends State<LoadingScreen1> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final role = prefs.getString('role');

    if (userId != null && role != null) {
      if (!mounted) return;

      // START NOTIFICATION LISTENER FOR AUTO LOGGED IN USER
      NotificationService.startListening(userId);

      switch (role) {
        case 'Bus Secretary':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BusSecretaryDashboard(userId: userId),
            ),
          );
          break;
        case 'Driver':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DriverDashboard(userId: userId)),
          );
          break;
        case 'Student':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentDashboard(userId: userId)),
          );
          break;
        case 'Bus Attendant':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BusAttendantDashboard(userId: userId),
            ),
          );
          break;
        default:
          break;
      }
    }
  }

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
