import 'package:get/get.dart';
import '../models/comparison.dart';
import '../services/api_service.dart';

class HistoryController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final RxList<Comparison> history = <Comparison>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }
  
  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final result = await _apiService.getHistory();
      history.value = result;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> refreshHistory() async {
    await loadHistory();
  }
}
