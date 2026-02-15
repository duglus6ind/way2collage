import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirebase() async {
  await FirebaseFirestore.instance.collection('test').add({
    'status': 'connected',
  });
}
