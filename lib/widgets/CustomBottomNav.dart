import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/screens/StudentMap.dart';
import 'package:bus_tracker/screens/DriverMap.dart';
import 'package:bus_tracker/screens/AttendantMap.dart';
import 'package:bus_tracker/screens/SecretaryMap.dart';
import 'package:bus_tracker/screens/ProfilePage.dart';

enum NavTab { map, home, profile }

class CustomBottomNav extends StatelessWidget {
  final String userId;
  final NavTab activeTab;

  const CustomBottomNav({
    super.key,
    required this.userId,
    required this.activeTab,
  });

  Future<void> _navigateToMap(BuildContext context) async {
    if (activeTab == NavTab.map) return;
    
    final doc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    if (!doc.exists) return;
    final role = doc.data()?['Role'];
    
    Widget mapWidget;
    if (role == 'Driver') {
      mapWidget = DriverMap(userId: userId);
    } else if (role == 'Bus Attendant') {
      mapWidget = AttendantMap(userId: userId);
    } else if (role == 'Bus Secretary') {
      mapWidget = SecretaryMap(userId: userId);
    } else {
      mapWidget = StudentMap(userId: userId);
    }

    if (context.mounted) {
      if (activeTab == NavTab.home) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => mapWidget));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => mapWidget));
      }
    }
  }

  void _navigateToHome(BuildContext context) {
    if (activeTab == NavTab.home) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _navigateToProfile(BuildContext context) {
    if (activeTab == NavTab.profile) return;
    if (activeTab == NavTab.home) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          
          _buildNavItem(
            icon: Icons.directions_bus,
            tab: NavTab.map,
            isLeft: true,
            onTap: () => _navigateToMap(context),
          ),
          
          _buildNavItem(
            icon: Icons.home,
            tab: NavTab.home,
            isCenter: true,
            onTap: () => _navigateToHome(context),
          ),
          
          _buildNavItem(
            icon: Icons.person,
            tab: NavTab.profile,
            isRight: true,
            onTap: () => _navigateToProfile(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required NavTab tab,
    required VoidCallback onTap,
    bool isLeft = false,
    bool isRight = false,
    bool isCenter = false,
  }) {
    final bool isActive = activeTab == tab;

    double? left;
    double? right;

    if (isLeft) left = 60;
    if (isRight) right = 60;

    final double bottomOffset = isActive ? 18.0 : 23.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      left: left,
      right: right,
      bottom: bottomOffset,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 68 : 44,
          height: isActive ? 68 : 44,
          padding: EdgeInsets.all(isActive ? 6 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: isActive ? const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ] : [],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.black : Colors.white,
            ),
            child: Icon(
              icon, 
              color: isActive ? Colors.white : Colors.black, 
              size: isActive ? 30 : 24,
            ),
          ),
        ),
      ),
    );
  }
}
