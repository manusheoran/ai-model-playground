import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/model_response.dart';
import '../models/comparison.dart';

class ApiService {
  // Change this to your backend URL
  // For iOS Simulator: http://localhost:3000
  // For Android Emulator: http://10.0.2.2:3000
  // For physical device: http://YOUR_COMPUTER_IP:3000
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<List<ModelResponse>> compareModels(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> responsesJson = data['responses'];
        return responsesJson.map((json) => ModelResponse.fromJson(json)).toList();
      } else {
        throw Exception('Failed to compare models: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error comparing models: $e');
    }
  }

  Future<List<Comparison>> getHistory({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Comparison.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading history: $e');
    }
  }
}
