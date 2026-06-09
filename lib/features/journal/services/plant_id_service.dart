import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/config/api_keys.dart';

class PlantIdService {
  final String _baseUrl = 'https://plant.id/api/v3/health_assessment?details=description,treatment';

  Future<Map<String, String>> identifyDisease(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      final Map<String, dynamic> requestBody = {
        'images': [base64Image],
        'similar_images': true,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': ApiKeys.plantIdApiKey,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        final isHealthy = data['result']['is_healthy']['binary'];
        
        if (isHealthy == true) {
          return {
            'diagnosis': 'Tanaman Sehat',
            'notes': 'Tidak terdeteksi adanya penyakit. Pertahankan jadwal penyiraman dan perawatan yang baik!',
          };
        } else {
          final diseases = data['result']['disease']['suggestions'] as List;
          
          if (diseases.isNotEmpty) {
            final suggestion = diseases[0];
            final name = suggestion['name'] ?? 'Penyakit Tidak Diketahui';
            final probability = ((suggestion['probability'] ?? 0.0) * 100).toStringAsFixed(1);
            
            String notesStr = 'Akurasi AI: $probability%\n';
            final details = suggestion['details'];
            
            if (details != null) {
              if (details['description'] != null) {
                notesStr += '\nDeskripsi:\n${details['description']}\n';
              }
              if (details['treatment'] != null) {
                final treatment = details['treatment'];
                
                if (treatment is Map) {
                  final preventionList = treatment['prevention'] as List<dynamic>? ?? [];
                  final biologicalList = treatment['biological'] as List<dynamic>? ?? [];
                  final chemicalList = treatment['chemical'] as List<dynamic>? ?? [];
                  
                  if (preventionList.isNotEmpty) {
                    notesStr += '\nPencegahan:\n- ${preventionList.join('\n- ')}\n';
                  }
                  if (biologicalList.isNotEmpty) {
                    notesStr += '\nPerawatan Biologis:\n- ${biologicalList.join('\n- ')}\n';
                  }
                  if (chemicalList.isNotEmpty) {
                    notesStr += '\nPerawatan Kimia:\n- ${chemicalList.join('\n- ')}\n';
                  }
                } else {
                  notesStr += '\nSaran Perawatan:\n${treatment.toString()}\n';
                }
              }
            }

            return {
              'diagnosis': name,
              'notes': notesStr.trim(),
            };
          }
          return {
            'diagnosis': 'Tidak Teridentifikasi',
            'notes': 'Gambar kurang jelas atau penyakit tidak dikenali oleh sistem.',
          };
        }
      } else {
        throw Exception('Gagal menghubungi API Plant.id (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memproses gambar: $e');
    }
  }
}