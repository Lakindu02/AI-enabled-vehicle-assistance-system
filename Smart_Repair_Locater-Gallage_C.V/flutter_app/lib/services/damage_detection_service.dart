import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/damage_detection_result.dart';

class DamageDetectionService {
  // Update this to your computer's IP address when testing on physical device
  // For iOS Simulator: use 'localhost' or '127.0.0.1'
  // For Android Emulator: use '10.0.2.2'
  // For Physical Device: use your computer's local IP (e.g., '192.168.1.100')
  static const String baseUrl = 'http://localhost:8007';

  /// Detect damage from an image file
  Future<DamageDetectionResult?> detectDamage(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/detect-damage');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add the image file
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'file',
        imageStream,
        imageLength,
        filename: imageFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      // Send request
      print('Sending damage detection request...');
      var streamedResponse = await request.send();

      // Get response
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DamageDetectionResult.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during damage detection: $e');
      return null;
    }
  }

  /// Check if the API server is reachable
  Future<bool> checkServerConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Server connection check failed: $e');
      return false;
    }
  }

  /// Get complete assessment with location (optional - for future use)
  Future<Map<String, dynamic>?> getCompleteAssessment(
    File imageFile, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/complete-assessment');

      var request = http.MultipartRequest('POST', uri);

      // Add the image file
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'file',
        imageStream,
        imageLength,
        filename: imageFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      // Add location if provided
      if (latitude != null && longitude != null) {
        request.fields['latitude'] = latitude.toString();
        request.fields['longitude'] = longitude.toString();
      }

      // Send request
      print('Sending complete assessment request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during complete assessment: $e');
      return null;
    }
  }
}
