import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _serviceId = 'service_2suyukt';
  static const String _templateId = 'template_t7jqh6n';
  static const String _publicKey = 'kc_JnP7MO2-_rvlDP';

  static Future<bool> sendOTP(String email, String otp) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {'to_email': email, 'otp': otp},
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('EmailJS Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Email Service Error: $e');
      return false;
    }
  }
}
