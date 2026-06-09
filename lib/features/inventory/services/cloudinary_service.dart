import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_keys.dart';

class CloudinaryService {
  Future<String?> uploadImage(String filePath) async {
    const cloudName = ApiKeys.cloudinaryCloudName;
    const uploadPreset = ApiKeys.cloudinaryUploadPreset;

    // Check for placeholders
    if (cloudName == 'YOUR_CLOUDINARY_CLOUD_NAME' || 
        uploadPreset == 'YOUR_CLOUDINARY_UPLOAD_PRESET' || 
        cloudName.trim().isEmpty || 
        uploadPreset.trim().isEmpty) {
      debugPrint('Cloudinary credentials are not configured in api_keys.dart. Skipping upload.');
      return null;
    }

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed: Status Code ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }
}
