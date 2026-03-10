import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bus_tracker/screens/SecretaryEmergencyDetail.dart';
import 'package:bus_tracker/screens/DriverEmergencyList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Notifications')
          .where('toUserId', isEqualTo: widget.userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
            .where('toUserId', isEqualTo: widget.userId)
            // .orderBy removed to avoid missing index error. Sorting locally instead.
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading notifications"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          var notifications = snapshot.data!.docs.toList();

          // Sort locally to avoid needing a Firestore composite Index
          notifications.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime); // Descending
          });

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;

              final Timestamp? ts = data['createdAt'];
              final DateTime? dateTime = ts?.toDate();

              final String formattedDate = dateTime != null
                  ? _formatDate(dateTime)
                  : "";
              final String formattedTime = dateTime != null
                  ? _formatTime(dateTime)
                  : "";

              return GestureDetector(
                onTap: () async {
                  final payload = data['payload'] as String?;
                  if (payload != null && payload.startsWith("EMERGENCY|")) {
                    final parts = payload.split("|");
                    if (parts.length >= 2) {
                      final emergencyId = parts[1];
                      final prefs = await SharedPreferences.getInstance();
                      final role = prefs.getString('role');

                      if (role == 'Bus Secretary') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SecretaryEmergencyDetail(
                              emergencyId: emergencyId,
                            ),
                          ),
                        );
                      } else if (role == 'Driver' || role == 'Bus Attendant') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverEmergencyList(),
                          ),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['message'] ?? "",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();

  if (now.difference(date).inDays == 0) {
    return "Today";
  } else if (now.difference(date).inDays == 1) {
    return "Yesterday";
  } else {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

String _formatTime(DateTime date) {
  return DateFormat('hh:mm a').format(date);
}
