import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class SecretaryEmergencyDetail extends StatefulWidget {
  final String emergencyId;
  const SecretaryEmergencyDetail({super.key, required this.emergencyId});

  @override
  State<SecretaryEmergencyDetail> createState() =>
      _SecretaryEmergencyDetailState();
}

class _SecretaryEmergencyDetailState extends State<SecretaryEmergencyDetail> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  Future<void> _sendReply(String reporterId, String title) async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;

    setState(() => _isReplying = true);

    try {
      await FirebaseFirestore.instance
          .collection('Emergencies')
          .doc(widget.emergencyId)
          .update({'secretaryReply': replyText, 'status': 'Acknowledged'});

      // Notify the reporter
      await NotificationService.sendNotification(
        toUserId: reporterId,
        title: "Reply to your Emergency",
        message: "Secretary handled: $title",
        busId: '',
        busName: 'Emergency Update',
        payload: "EMERGENCY|${widget.emergencyId}",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply sent successfully!')));
      _replyController.clear();
      FocusScope.of(context).unfocus(); // Close keyboard
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: const Text("Emergency Details"),
        backgroundColor: const Color(0xFF095C42),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Emergencies')
            .doc(widget.emergencyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text("Error or Emergency not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'] ?? 'Emergency';
          final description = data['description'] ?? 'No description provided';
          final status = data['status'] ?? 'Pending';
          final locationStr = data['locationString'] ?? 'Not provided';
          final secretaryReply = data['secretaryReply'] ?? '';
          final reporterId = data['reporterId'] ?? '';
          final Timestamp? ts = data['createdAt'];

          String dateStr = '';
          if (ts != null) {
            dateStr = DateFormat('dd MMM yyyy - hh:mm a').format(ts.toDate());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Pending'
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Reported: $dateStr",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locationStr,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  "Reporter Details:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (reporterId.isNotEmpty)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(reporterId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const Text("Reporter details not found.");
                      }
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final name = userData['Name'] ?? 'Unknown';
                      final role = userData['Role'] ?? 'Unknown Role';
                      final phone = userData['PhoneNumber'] ?? 'N/A';
                      final busId = userData['AssignedBusId'] ?? 'N/A';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    role,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(phone),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.directions_bus,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text("Bus: $busId"),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  const Text("No reporter ID available."),

                const SizedBox(height: 24),
                const Text(
                  "Description:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(thickness: 1.5),
                const SizedBox(height: 16),

                const Text(
                  "Secretary Response:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (secretaryReply.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF095C42)),
                    ),
                    child: Text(
                      secretaryReply,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "This emergency has been acknowledged.",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _replyController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          "Enter your response/instruction for the driver...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF095C42),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF095C42),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isReplying || reporterId.isEmpty
                          ? null
                          : () => _sendReply(reporterId, title),
                      child: _isReplying
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Acknowledge & Send Reply",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
