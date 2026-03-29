import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bus_tracker/services/notification_service.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class EmergencyReportScreen extends StatefulWidget {
  final String userId;
  const EmergencyReportScreen({super.key, required this.userId});

  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = false;
  bool _includeLocation = false;
  Position? _currentPosition;
  String _locationString = '';

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      setState(() => _includeLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        setState(() => _includeLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      setState(() => _includeLocation = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _locationString =
          "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    });
  }

  Future<void> _submitEmergency() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the emergency')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final emergencyDoc = await FirebaseFirestore.instance
          .collection('Emergencies')
          .add({
            'reporterId': widget.userId,
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'hasLocation': _includeLocation,
            'latitude': _includeLocation && _currentPosition != null
                ? _currentPosition!.latitude
                : null,
            'longitude': _includeLocation && _currentPosition != null
                ? _currentPosition!.longitude
                : null,
            'locationString': _includeLocation
                ? _locationString
                : 'Not provided',
            'status': 'Pending',
            'secretaryReply': '',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Notify the Secretary
      final secretaryQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('Role', isEqualTo: 'Bus Secretary')
          .get();

      final emergencyId = emergencyDoc.id;

      for (var doc in secretaryQuery.docs) {
        final secId = doc.id;
        await NotificationService.sendNotification(
          toUserId: secId,
          title: "New Emergency: ${_titleController.text.trim()}",
          message: "A new emergency has been reported.",
          busId:
              '', // Ideally we fetch the user's busId, but leaving empty for flexibility if unassigned
          busName: 'Emergency Alert',
          payload: "EMERGENCY|$emergencyId",
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency reported successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to report: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: const Text("Report Emergency"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Emergency Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title (e.g., Engine Breakdown)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description (Optional)",
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Location Options",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text("Include current location"),
              value: _includeLocation,
              activeColor: Colors.red.shade700,
              onChanged: (val) {
                setState(() => _includeLocation = val);
                if (val) {
                  _getCurrentLocation();
                }
              },
            ),
            if (_includeLocation && _locationString.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Captured Location: $_locationString",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _isLoading ? null : _submitEmergency,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Report Emergency",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
