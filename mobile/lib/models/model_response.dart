class ModelResponse {
  final String modelId;
  final String modelName;
  final String provider;
  final String responseText;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int responseTimeMs;
  final double estimatedCost;
  final String? error;

  ModelResponse({
    required this.modelId,
    required this.modelName,
    required this.provider,
    required this.responseText,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.responseTimeMs,
    required this.estimatedCost,
    this.error,
  });

  factory ModelResponse.fromJson(Map<String, dynamic> json) {
    return ModelResponse(
      modelId: json['modelId'] ?? '',
      modelName: json['modelName'] ?? '',
      provider: json['provider'] ?? '',
      responseText: json['responseText'] ?? '',
      promptTokens: json['promptTokens'] ?? 0,
      completionTokens: json['completionTokens'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
      responseTimeMs: json['responseTimeMs'] ?? 0,
      estimatedCost: (json['estimatedCost'] ?? 0).toDouble(),
      error: json['error'],
    );
  }

  factory ModelResponse.fromHistoryJson(Map<String, dynamic> json) {
    return ModelResponse(
      modelId: '',
      modelName: json['model_name'] ?? '',
      provider: '',
      responseText: json['response_text'] ?? '',
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
      responseTimeMs: json['response_time_ms'] ?? 0,
      estimatedCost: double.parse(json['estimated_cost']?.toString() ?? '0'),
      error: json['error'],
    );
  }

  bool get hasError => error != null && error!.isNotEmpty;
}
