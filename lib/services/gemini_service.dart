import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../secrets.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiApiKey,
    );
  }

  Future<List<Map<String, dynamic>>> analyzeFoodImage(String imagePath) async {
    // For Web, imagePath is a blob URL. We fetch bytes via http.
    final responseBytes = await http.get(Uri.parse(imagePath));
    final imageBytes = responseBytes.bodyBytes;
    
    final content = [
      Content.multi([
        TextPart(
            'Analyze this food image. Identify the items. Estimate the weight in grams for each based on visual cues (portion size). Calculate approximate calories, protein, carbs, and fat for that estimated weight. Return a raw JSON object (NO MARKDOWN, NO CODE BLOCKS, just the raw json string) with this structure: { "items": [ { "name": "Food Name", "weight_grams": 100, "calories": 200, "protein_g": 10, "carbs_g": 20, "fat_g": 5 } ] }'),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    try {
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text == null) return [];

      // Clean up potential markdown code blocks if Gemini ignores "NO MARKDOWN"
      String cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();

      final data = jsonDecode(cleanText);
      if (data is Map && data.containsKey('items')) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
      return [];
    } catch (e) {
      print('Gemini Error: $e');
      // Fallback or rethrow
      return [];
    }
  }
}
