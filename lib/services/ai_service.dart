import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AIService {
  static const String _baseUrl = 'https://health-sync.online/ai/api/ai';

  Future<String> getAdvice(String token, String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/text'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? "AI молчит...";
      } else {
        throw Exception("Ошибка сервера AI: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Не удалось связаться с AI");
    }
  }

  // 2. Анализ фото (Картинка -> JSON с названием)
  Future<Map<String, dynamic>> analyzeFoodImage(
    String token,
    String base64Image,
  ) async {
    try {
      const prompt =
          "Analyze this image. If it contains food or drink: "
          "1. Estimate calories (key 'calories'). "
          "2. Estimate water in ml (key 'water_ml'). "
          "3. Name the food/drink in Russian (key 'name'). "
          "Return ONLY JSON: {\"calories\": 100, \"water_ml\": 0, \"name\": \"Яблоко\"}. "
          "If no food, return {\"calories\": 0, \"water_ml\": 0, \"name\": \"\"}.";

      final response = await http
          .post(
            Uri.parse('$_baseUrl/image'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'image_base64': base64Image, 'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String answer = data['answer'] ?? "";

        answer = answer.replaceAll('```json', '').replaceAll('```', '').trim();

        final parsed = jsonDecode(answer);
        return {
          'calories': parsed['calories'] ?? 0,
          'water_ml': parsed['water_ml'] ?? 0,
          'name': parsed['name'] ?? "",
        };
      } else {
        throw Exception("Ошибка сервера");
      }
    } catch (e) {
      debugPrint("AI Image Error: $e");
      return {'calories': 0, 'water_ml': 0, 'name': ""};
    }
  }
}
