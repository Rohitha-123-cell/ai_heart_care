import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey = "AIzaSyAGEgzDDbUHtvJAOdOUqmPJADU-7N995_Y";

  Future<String> _sendRequest(String prompt, {File? image}) async {
    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey");

      List<Map<String, dynamic>> parts = [{"text": prompt}];

      if (image != null) {
        final bytes = await image.readAsBytes();
        parts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Encode(bytes),
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
    // Check if user is asking about health
    String lowerMessage = message.toLowerCase();
    if (!lowerMessage.contains('symptom') && 
        !lowerMessage.contains('health') && 
        !lowerMessage.contains('medicine') && 
        !lowerMessage.contains('doctor') && 
        !lowerMessage.contains('pain') && 
        !lowerMessage.contains('fever') && 
        !lowerMessage.contains('cold') && 
        !lowerMessage.contains('cough') && 
        !lowerMessage.contains('headache') &&
        !lowerMessage.contains('ill') &&
        !lowerMessage.contains('sick') &&
        !lowerMessage.contains('medical')) {
      return "I'm sorry, but I can only assist with health-related questions. Please ask about symptoms, medicines, or medical concerns.";
    }
    
    return await _sendRequest("You are a helpful medical assistant. Answer concisely in 2-3 sentences. Ask if they have other symptoms. No disclaimer needed.\nUser: $message");
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

  // Skin Detection (REAL VISION AI now!)
  Future<String> analyzeImage(File image) =>
      _sendRequest(
          "Analyze this skin photo. Detect issues like acne, eczema, rash, allergy. Give confidence % and brief advice in 2-3 sentences. No disclaimer needed.",
          image: image);
}