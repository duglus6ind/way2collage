import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/screens/EmergencyReportScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class DriverEmergencyList extends StatefulWidget {
  const DriverEmergencyList({super.key});

  @override
  State<DriverEmergencyList> createState() => _DriverEmergencyListState();
}

class _DriverEmergencyListState extends State<DriverEmergencyList> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: const Text("My Reported Emergencies"),
        backgroundColor: const Color(0xFF095C42),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFEEEAEA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Emergencies')
            .where('reporterId', isEqualTo: userId)
            // .orderBy removed to avoid missing index error. Sorting locally instead.
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading emergencies"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No emergencies reported yet."));
          }

          var emergencies = snapshot.data!.docs.toList();

          // Sort locally to avoid needing a Firestore composite Index
          emergencies.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            // Descending
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: emergencies.length,
            itemBuilder: (context, index) {
              final data = emergencies[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Emergency';
              final status = data['status'] ?? 'Pending';
              final locationStr =
                  data['locationString'] ?? 'Location not provided';
              final Timestamp? ts = data['createdAt'];
              final String secretaryReply = data['secretaryReply'] ?? '';

              String dateStr = '';
              if (ts != null) {
                dateStr = DateFormat('dd MMM yyyy hh:mm a').format(ts.toDate());
              }

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'Pending'
                                  ? Colors.orange
                                  : Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Location: $locationStr",
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Reported: $dateStr",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      if (secretaryReply.isNotEmpty) ...[
                        const Divider(height: 20, thickness: 1),
                        const Text(
                          "Secretary Reply:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF095C42),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          secretaryReply,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF095C42),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmergencyReportScreen(userId: userId!),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
