import 'package:bus_tracker/screens/BulkUsersUploadScreen.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/ShowUser.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF095C42),
        elevation: 0,
        title: const Text(
          "User Management",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // SHOW / ADD USERS
            _blueCard(
              child: Column(
                children: [
                  _whiteButton("SHOW USERS", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ShowUsersScreen(),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  _whiteButton("ADD USERS", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BulkUserUploadScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // BLUE CARD
  Widget _blueCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF095C42),
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      ),
    );
  }

  //  WHITE BUTTON
  Widget _whiteButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  //  GREY BUTTON
  // Widget _greyButton(String text, VoidCallback onTap) {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: ElevatedButton(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: const Color(0xFFE0E0E0),
  //         foregroundColor: Colors.black,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(18),
  //         ),
  //         padding: const EdgeInsets.symmetric(vertical: 18),
  //       ),
  //       onPressed: onTap,
  //       child: Text(text, style: const TextStyle(fontSize: 16)),
  //     ),
  //   );
  // }
}
