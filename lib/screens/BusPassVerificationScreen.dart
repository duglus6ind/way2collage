import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class BusPassVerificationScreen extends StatefulWidget {
  const BusPassVerificationScreen({super.key});

  @override
  State<BusPassVerificationScreen> createState() => _BusPassVerificationScreenState();
}

class _BusPassVerificationScreenState extends State<BusPassVerificationScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Helper to calculate expiry (6 months = 180 days approx)
  bool _isPassValid(Timestamp? activationDate) {
    if (activationDate == null) return false;
    final DateTime start = activationDate.toDate();
    final DateTime expiry = start.add(const Duration(days: 180));
    return DateTime.now().isBefore(expiry);
  }

  String _getValidityDate(Timestamp? activationDate) {
    if (activationDate == null) return "N/A";
    final DateTime start = activationDate.toDate();
    final DateTime expiry = start.add(const Duration(days: 180));
    return DateFormat('dd MMM yyyy').format(expiry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),
      appBar: AppBar(
        title: const Text(
          "Bus Pass Verification",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF095C42),
        elevation: 0,
        leading: const CustomBackButton(),
      ),
      body: Column(
        children: [
          // SEARCH SECTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search by Student ID or Name",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // STUDENT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('Role', isEqualTo: 'Student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No students found"));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['Name'].toString().toLowerCase();
                  final userId = data['UserId'].toString().toLowerCase();
                  final passStatus = data['BusPassStatus']?.toString().toUpperCase() ?? '';
                  
                  // Filter by search query
                  final matchesSearch = name.contains(_searchQuery) || userId.contains(_searchQuery);
                  
                  // Filter by approval status
                  final isApproved = passStatus == 'APPROVED';
                  
                  return matchesSearch && isApproved;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No matching students"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final Timestamp? activation = data['ActivationDate'];
                    final bool isValid = _isPassValid(activation);
                    final String expiryDate = _getValidityDate(activation);

                    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final String attendanceId = "${data['UserId']}_$today";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Attendance')
                            .doc(attendanceId)
                            .snapshots(),
                        builder: (context, attendanceSnap) {
                          final bool isBoarded = attendanceSnap.hasData &&
                              attendanceSnap.data!.exists &&
                              (attendanceSnap.data!['isBoarded'] ?? false);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isValid
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              child: Icon(
                                isValid ? Icons.check_circle : Icons.error,
                                color: isValid ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              data['Name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ID: ${data['UserId']}"),
                                Text("Expires: $expiryDate", style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isValid ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isValid ? "VALID" : "EXPIRED",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: isBoarded,
                                  activeColor: const Color(0xFF095C42),
                                  onChanged: isValid
                                      ? (val) {
                                          FirebaseFirestore.instance
                                              .collection('Attendance')
                                              .doc(attendanceId)
                                              .set({
                                            'userId': data['UserId'],
                                            'date': today,
                                            'isBoarded': val,
                                            'timestamp': FieldValue.serverTimestamp(),
                                          });
                                        }
                                      : null, // Disable if expired
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
