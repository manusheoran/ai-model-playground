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
    final startTime = DateTime.now();
    print('[ApiService] Starting API request at ${startTime.toIso8601String()}');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Request timed out after 45 seconds'),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      print('[ApiService] Response received after ${duration}ms');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverTime = data['serverTotalTime'];
        final networkTime = duration - (serverTime ?? 0);
        
        print('[ApiService] Server processing: ${serverTime}ms, Network latency: ~${networkTime}ms');
        
        final List<dynamic> responsesJson = data['responses'];
        final parseStartTime = DateTime.now();
        final result = responsesJson.map((json) => ModelResponse.fromJson(json)).toList();
        final parseTime = DateTime.now().difference(parseStartTime).inMilliseconds;
        
        print('[ApiService] JSON parsing took ${parseTime}ms');
        print('[ApiService] Total client time: ${DateTime.now().difference(startTime).inMilliseconds}ms');
        
        return result;
      } else {
        throw Exception('Failed to compare models: ${response.body}');
      }
    } catch (e) {
      final errorTime = DateTime.now().difference(startTime).inMilliseconds;
      print('[ApiService] Error after ${errorTime}ms: $e');
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
