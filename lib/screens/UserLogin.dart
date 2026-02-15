import 'package:bus_tracker/screens/ForcePasswordReset.dart';
import 'package:bus_tracker/screens/ForgotPassword.dart';
import 'package:bus_tracker/utils/PasswordUtils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import dashboards
import 'package:bus_tracker/screens/BusSecretaryDashboard.dart';
import 'package:bus_tracker/screens/BusAttendantDashboard.dart';
import 'package:bus_tracker/screens/DriverDashboard.dart';
import 'package:bus_tracker/screens/StudentDashboard.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});
  @override
  UserLoginState createState() => UserLoginState();
}

class UserLoginState extends State<UserLogin> {
  String textField1 = '';
  String textField2 = '';
  bool _obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 🔹 TOP GREEN AREA
          Container(
            height: size.height * 0.55,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF198B48),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 🔹 BOTTOM WHITE AREA
          Positioned(
            bottom: 0,
            child: Container(
              height: size.height * 0.45,
              width: size.width,
              color: Colors.white,
            ),
          ),

          // 🔹 LOGIN CARD
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
                        "Login",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // USERNAME
                      _loginField(
                        hint: "Username",

                        onChanged: (v) => textField1 = v,
                      ),
                      const SizedBox(height: 18),

                      // PASSWORD
                      _loginField(
                        hint: "Password",
                        obscure: _obscurePassword,
                        onChanged: (v) => textField2 = v,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 CIRCULAR LOGIN BUTTON
                GestureDetector(
                  onTap: loginUser,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0CEA26),
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
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

  Widget _loginField({
    required String hint,
    required Function(String) onChanged,
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
        obscureText: obscure,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500, // reduced opacity grey
            fontWeight: FontWeight.w600, // slightly bold
            fontSize: 15,
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

  Future<void> loginUser() async {
    if (textField1.isEmpty || textField2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter username and password")),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(textField1);
      final doc = await docRef.get();

      if (!doc.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not found")));
        return;
      }

      final data = doc.data()!;
      final dbPassword = data['Password'];
      final role = data['Role'];
      final bool forceReset = data['ForcePasswordReset'] ?? false;

      if (forceReset) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ForcePasswordResetScreen(userId: textField1, role: role),
          ),
        );

        if (result == true) {
          // Continue to dashboard after successful reset
        } else {
          return;
        }
      }

      final bool isActive = data['Active'] ?? true;

      if (!isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Your account has been deactivated. Please contact the Bus Secretary.",
            ),
          ),
        );
        return;
      }

      int failedAttempts = data['FailedAttempts'] ?? 0;
      Timestamp? firstFailedAtTs = data['FirstFailedAt'];
      Timestamp? lockUntilTs = data['LockUntil'];

      final DateTime now = DateTime.now();

      //  CHECK ACCOUNT LOCK
      if (lockUntilTs != null) {
        final lockUntil = lockUntilTs.toDate();
        if (now.isBefore(lockUntil)) {
          final remaining = lockUntil.difference(now).inMinutes.clamp(1, 60);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Account locked. Try again in $remaining minutes."),
            ),
          );
          return;
        } else {
          // Lock expired → reset everything
          await docRef.update({
            'FailedAttempts': 0,
            'FirstFailedAt': null,
            'LockUntil': null,
          });
          failedAttempts = 0;
          firstFailedAtTs = null;
        }
      }
      final enteredHashedPassword = hashPassword(textField2);
      //  WRONG PASSWORD
      if (dbPassword != enteredHashedPassword) {
        // First failed attempt
        if (firstFailedAtTs == null) {
          await docRef.update({
            'FailedAttempts': 1,
            'FirstFailedAt': Timestamp.fromDate(now),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Incorrect password. Attempt 1 of 5")),
          );
          return;
        }

        final firstFailedAt = firstFailedAtTs.toDate();

        //  If 1 hour passed → reset counter
        if (now.difference(firstFailedAt).inHours >= 1) {
          await docRef.update({
            'FailedAttempts': 1,
            'FirstFailedAt': Timestamp.fromDate(now),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Previous attempts expired. Attempt 1 of 5"),
            ),
          );
          return;
        }

        // Increment attempts
        failedAttempts++;

        if (failedAttempts >= 5) {
          await docRef.update({
            'FailedAttempts': 0,
            'FirstFailedAt': null,
            'LockUntil': Timestamp.fromDate(now.add(const Duration(hours: 1))),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Too many failed attempts. Account locked for 1 hour.",
              ),
            ),
          );
        } else {
          await docRef.update({'FailedAttempts': failedAttempts});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Incorrect password. Attempt $failedAttempts of 5.",
              ),
            ),
          );
        }
        return;
      }

      //  SUCCESSFUL LOGIN → RESET SECURITY DATA
      await docRef.update({
        'FailedAttempts': 0,
        'FirstFailedAt': null,
        'LockUntil': null,
      });

      //  REDIRECT BY ROLE
      switch (role) {
        case 'Bus Secretary':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BusSecretaryDashboard(userId: textField1),
            ),
          );
          break;

        case 'Driver':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DriverDashboard(userId: textField1),
            ),
          );
          break;

        case 'Student':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDashboard(userId: textField1),
            ),
          );
          break;

        case 'Bus Attendant':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BusAttendantDashboard(userId: textField1),
            ),
          );
          break;

        default:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Invalid user role")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }
}
