import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../services/ai_service.dart';
import '../chatbot/chat_screen.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final AIService _aiService = AIService();
  
  bool _isAnalyzing = false;
  String? _analysisResult;

  List<String> _commonSymptoms = [
    'Headache',
    'Fever',
    'Cough',
    'Fatigue',
    'Nausea',
    'Chest Pain',
    'Shortness of Breath',
    'Dizziness',
    'Body Aches',
    'Sore Throat',
  ];

  List<String> _selectedSymptoms = [];

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  Future<void> _analyzeSymptoms() async {
    if (_selectedSymptoms.isEmpty && _symptomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or enter symptoms")),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final symptoms = _selectedSymptoms.join(', ');
      final additional = _symptomController.text.trim();
      final allSymptoms = additional.isNotEmpty 
          ? '$symptoms${symptoms.isNotEmpty ? ', ' : ''}$additional'
          : symptoms;

      final result = await _aiService.analyzeSymptoms(allSymptoms);
      
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Analysis failed: ${e.toString()}")),
        );
      }
    }
  }

  void _chatWithAI() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                ),
              ),
            ),
            
            Positioned(
              top: -width * 0.3,
              right: -width * 0.2,
              child: Container(
                width: width * 0.8,
                height: width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width * 0.4),
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -width * 0.3,
              left: -width * 0.2,
              child: Container(
                width: width * 0.8,
                height: width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width * 0.4),
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(width * 0.025),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(width * 0.03),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: width * 0.06,
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.04),
                        const Expanded(
                          child: Text(
                            "Symptom Checker",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _chatWithAI,
                          child: Container(
                            padding: EdgeInsets.all(width * 0.025),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(width * 0.03),
                            ),
                            child: Icon(
                              Icons.chat_bubble,
                              color: Colors.white,
                              size: width * 0.06,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          GlassCard(
                            child: Padding(
                              padding: EdgeInsets.all(width * 0.04),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(width * 0.02),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(width * 0.02),
                                        ),
                                        child: const Icon(
                                          Icons.info_outline,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      SizedBox(width: width * 0.03),
                                      const Expanded(
                                        child: Text(
                                          "Select your symptoms or describe how you feel",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.03),

                          // Common Symptoms
                          const Text(
                            "Common Symptoms",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: height * 0.015),
                          Wrap(
                            spacing: width * 0.025,
                            runSpacing: width * 0.025,
                            children: _commonSymptoms.map((symptom) {
                              final isSelected = _selectedSymptoms.contains(symptom);
                              return GestureDetector(
                                onTap: () => _toggleSymptom(symptom),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.035,
                                    vertical: height * 0.015,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Colors.orange 
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(width * 0.06),
                                    border: Border.all(
                                      color: isSelected 
                                          ? Colors.orange 
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    symptom,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          SizedBox(height: height * 0.03),

                          // Additional Symptoms TextField
                          const Text(
                            "Other Symptoms (Optional)",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: height * 0.015),
                          GlassCard(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                              child: TextField(
                                controller: _symptomController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: "Describe any other symptoms...",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.03),

                          // Analyze Button
                          CustomButton(
                            text: _isAnalyzing ? "Analyzing..." : "Analyze Symptoms",
                            onTap: _isAnalyzing ? () {} : _analyzeSymptoms,
                            isLoading: _isAnalyzing,
                          ),

                          SizedBox(height: height * 0.03),

                          // Analysis Result
                          if (_analysisResult != null) ...[
                            const Text(
                              "Analysis Result",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: height * 0.015),
                            GlassCard(
                              child: Padding(
                                padding: EdgeInsets.all(width * 0.04),
                                child: Text(
                                  _analysisResult!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          SizedBox(height: height * 0.03),

                          // Disclaimer
                          Container(
                            padding: EdgeInsets.all(width * 0.04),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(width * 0.03),
                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.red),
                                SizedBox(width: width * 0.03),
                                Expanded(
                                  child: Text(
                                    "This is not a medical diagnosis. Please consult a healthcare professional for accurate advice.",
                                    style: TextStyle(
                                      color: Colors.red.shade300,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: height * 0.03),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
