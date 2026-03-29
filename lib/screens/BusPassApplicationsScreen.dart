import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class BusPassApplicationsScreen extends StatefulWidget {
  const BusPassApplicationsScreen({super.key});

  @override
  State<BusPassApplicationsScreen> createState() => _BusPassApplicationsScreenState();
}

class _BusPassApplicationsScreenState extends State<BusPassApplicationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Paid', 'Pending', 'Partial'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF095C42),
        title: const Text(
          "Bus Pass Applications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const CustomBackButton(),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
                      selectedColor: const Color(0xFF095C42),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bus_pass_applications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF095C42)),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading applications"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No applications found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var applications = snapshot.data!.docs;

          applications = applications.where((doc) {
            if (_selectedFilter == 'All') return true;
            
            final data = doc.data() as Map<String, dynamic>;
            final paymentStatus = data['paymentStatus']?.toString().toLowerCase() ?? '';
            final transactionId = data['transactionId']?.toString() ?? 'N/A';
            
            String currentStatus = paymentStatus;
            if (currentStatus.isEmpty) {
              if (transactionId != 'N/A' && transactionId.isNotEmpty) {
                currentStatus = 'paid';
              } else {
                currentStatus = 'pending';
              }
            }
            
            return currentStatus == _selectedFilter.toLowerCase();
          }).toList();

          if (applications.isEmpty) {
            return const Center(
              child: Text(
                "No applications match this filter.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final doc = applications[index];
              final data = doc.data() as Map<String, dynamic>;

              final docId = doc.id;
              final name = data['name'] ?? 'Unknown';
              final admissionNumber = data['admissionNumber'] ?? 'Unknown';
              final department = data['department'] ?? 'Unknown';
              final semester = data['semester'] ?? 'Unknown';
              final status = data['status'] ?? 'PENDING';
              final transactionId = data['transactionId'] ?? 'N/A';
              final paymentStatus = data['paymentStatus'] ?? '';
              final userId = data['userId'] ?? '';

              String displayPaymentStatus = paymentStatus.toString().toUpperCase();
              if (displayPaymentStatus.isEmpty) {
                displayPaymentStatus = (transactionId != 'N/A' && transactionId.isNotEmpty) ? 'PAID' : 'PENDING';
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showTransactionDetails(context, data),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Admission No: $admissionNumber"),
                      Text("Department: $department"),
                      Text("Semester: $semester"),
                      const SizedBox(height: 4),
                      Row(
                         children: [
                           Text(
                             "Payment: ",
                             style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                           ),
                           Text(
                             displayPaymentStatus,
                             style: TextStyle(
                               fontSize: 13,
                               color: displayPaymentStatus == 'PAID' 
                                  ? Colors.green.shade700 
                                  : (displayPaymentStatus == 'PARTIAL' ? Colors.orange.shade700 : Colors.red.shade700),
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ]
                      ),
                      if (transactionId != 'N/A')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Transaction ID: $transactionId",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (status == 'PENDING')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(docId, 'REJECTED', userId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red.shade900,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Reject"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(docId, 'APPROVED', userId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade100,
                                  foregroundColor: Colors.green.shade900,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Approve"),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
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

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'APPROVED':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'REJECTED':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      default:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String docId, String newStatus, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bus_pass_applications')
          .doc(docId)
          .update({'status': newStatus});
      if (userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('Notifications').add({
          'toUserId': userId,
          'title':
              'Bus Pass Application ${newStatus == 'APPROVED' ? 'Approved' : 'Rejected'}',
          'message':
              'Your bus pass application has been ${newStatus.toLowerCase()}.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'BUS_PASS_STATUS',
        });
      }

      // Sync to Users collection only if status is APPROVED
      if (newStatus == 'APPROVED' && userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .update({
          'BusPassStatus': 'APPROVED',
          'ActivationDate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error updating application status: $e");
    }
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final transactionId = data['transactionId'] ?? 'N/A';
    final paymentStatus = data['paymentStatus'] ?? '';
    
    String displayPaymentStatus = paymentStatus.toString().toUpperCase();
    if (displayPaymentStatus.isEmpty) {
      displayPaymentStatus = (transactionId != 'N/A' && transactionId.isNotEmpty) ? 'PAID' : 'PENDING';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.receipt_long, color: Color(0xFF095C42)),
              SizedBox(width: 8),
              Text("Transaction Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Applicant", name),
              const SizedBox(height: 12),
              _detailRow("Status", displayPaymentStatus),
              const SizedBox(height: 12),
              if (transactionId != 'N/A' && transactionId.isNotEmpty)
                _detailRow("Transaction ID", transactionId),
              if (transactionId != 'N/A' && transactionId.isNotEmpty)
                const SizedBox(height: 12),
              if (displayPaymentStatus == 'PAID' || (transactionId != 'N/A' && transactionId.isNotEmpty))
                _detailRow("Amount", "₹3000.00"), // Default fee as per payment screen
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Color(0xFF095C42), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
