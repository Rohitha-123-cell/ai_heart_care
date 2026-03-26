import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey = "AIzaSyAvBMK-7WsIYP5Pj27pTX8F37BYWrKnzFM";
  Future<String> _sendRequest(String prompt, {Uint8List? imageBytes}) async {
    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey");

      List<Map<String, dynamic>> parts = [{"text": prompt}];

      if (imageBytes != null) {
        parts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Encode(imageBytes),
          }
        });
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-goog-api-key": apiKey,
        },
        body: jsonEncode({
          "contents": [{"parts": parts}]
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data["error"] != null) {
        throw Exception('API Error: ${data["error"]["message"]}');      }
      
      String result = data["candidates"][0]["content"]["parts"][0]["text"];
      
      // Add disclaimer to all responses
      return "$result\n\n⚠️ **Disclaimer**: This is AI-generated information for educational purposes only. Always consult a qualified healthcare professional for medical advice, diagnosis, or treatment.";
      
    } catch (e) {
      return "Sorry, I'm having trouble connecting to the AI service. Please check your internet connection and try again later.\n\nError: ${e.toString()}";
    }
  }

  // Chatbot
  Future<String> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return "Please enter your health question.";
    }
    
    return await _sendRequest(
      "You are a helpful medical assistant. Treat common misspellings like migrane for migraine as valid health queries."
      " If the user asks something non-health-related, politely redirect them back to health topics in one short sentence."
      " If the user mentions a symptom, disease, medicine, infection, or condition, answer concisely in 2-3 sentences and ask if they have other symptoms."
      " No disclaimer needed."
      "\nUser: $trimmedMessage",
    );
  }

  // Symptom Checker
  Future<String> checkSymptoms(String symptoms) =>
      _sendRequest("User symptoms: $symptoms. Suggest possible conditions in 2-3 bullet points with brief advice. Ask about other symptoms. No disclaimer needed.");

  // Symptom Analyzer
  Future<String> analyzeSymptoms(String symptoms) =>
      _sendRequest("User symptoms: $symptoms. Analyze and suggest possible conditions in a structured format with brief advice. Ask about other symptoms. No disclaimer needed.");

  // Medicine Info
  Future<String> getMedicineInfo(String medicine) =>
      _sendRequest("You are a friendly medical assistant. For the medicine '$medicine':\n\n1. **What is it?** - Give a simple 1-line explanation of what this medicine is (e.g., 'This is a common pain reliever' or 'This is an antibiotic for infections')\n\n2. **What is it used for?** - Explain in simple terms what this medicine helps with (e.g., 'Used to treat headaches, fever, and mild pain' or 'Helps fight bacterial infections')\n\n3. **How to take it** - Simple dosage instructions if available\n\n4. **Important things to know** - Any key warnings in plain language\n\nKeep it simple and easy to understand, like explaining to a friend. Use bullet points. No disclaimer needed.");

  // Skin Detection - accepts raw bytes (works on web + mobile)
  Future<String> analyzeImage(Uint8List imageBytes) =>
      _sendRequest(
          "Analyze this skin photo. Detect issues like acne, eczema, rash, allergy. Give confidence % and brief advice in 2-3 sentences. No disclaimer needed.",
          imageBytes: imageBytes);

  // Medicine identification from image bytes (works on web + mobile)
  Future<String> getMedicineInfoFromImage(Uint8List imageBytes) =>
      _sendRequest(
          "Look at this medicine packaging image. Identify the medicine name, what it is used for, dosage instructions, and key warnings. Be simple and friendly. Use bullet points. No disclaimer needed.",
          imageBytes: imageBytes);

  Future<String> summarizeDiseaseTrend({
    required String disease,
    required String region,
    required int latestCases,
    required int peakCases,
    required double averageCases,
    required int abnormalDays,
  }) =>
      _sendRequest(
        "You are a health data assistant. Summarize this local disease trend dashboard in 3 short bullet points for a college hackathon demo."
        "\nDisease: $disease"
        "\nRegion: $region"
        "\nLatest cases: $latestCases"
        "\nPeak cases: $peakCases"
        "\nAverage cases: ${averageCases.toStringAsFixed(1)}"
        "\nAbnormal high-trend days: $abnormalDays"
        "\nFocus on trend direction, risk hotspots, and one practical awareness suggestion. No disclaimer needed.",
      );
}
