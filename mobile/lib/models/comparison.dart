import 'model_response.dart';

class Comparison {
  final String id;
  final String prompt;
  final DateTime createdAt;
  final List<ModelResponse> responses;

  Comparison({
    required this.id,
    required this.prompt,
    required this.createdAt,
    required this.responses,
  });

  factory Comparison.fromJson(Map<String, dynamic> json) {
    return Comparison(
      id: json['comparison']['id'] ?? '',
      prompt: json['comparison']['prompt'] ?? '',
      createdAt: DateTime.parse(json['comparison']['created_at'] ?? DateTime.now().toIso8601String()),
      responses: (json['responses'] as List?)
              ?.map((r) => ModelResponse.fromHistoryJson(r))
              .toList() ??
          [],
    );
  }
}
