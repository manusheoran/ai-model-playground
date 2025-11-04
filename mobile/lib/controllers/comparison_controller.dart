import 'package:get/get.dart';
import '../models/model_response.dart';
import '../services/api_service.dart';

class ComparisonController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final RxList<ModelResponse> responses = <ModelResponse>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  Future<void> compareModels(String prompt) async {
    if (prompt.trim().isEmpty) {
      error.value = 'Please enter a prompt';
      return;
    }
    
    if (prompt.length > 10000) {
      error.value = 'Prompt is too long (max 10,000 characters)';
      return;
    }
    
    try {
      isLoading.value = true;
      error.value = '';
      responses.clear();
      
      final result = await _apiService.compareModels(prompt);
      responses.value = result;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  void clearResults() {
    responses.clear();
    error.value = '';
  }
}
