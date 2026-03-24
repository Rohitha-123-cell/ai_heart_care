import 'package:flutter/material.dart';
import '../../services/ai_copilot_service.dart';

class AICopilotScreen extends StatefulWidget {
  const AICopilotScreen({super.key});

  @override
  State<AICopilotScreen> createState() => _AICopilotScreenState();
}

class _AICopilotScreenState extends State<AICopilotScreen> {
  final AICopilotService _copilotService = AICopilotService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  
  bool _isLoading = false;
  bool _showRecommendations = false;
  String _recommendations = "";
  
  // Health inputs
  double _bmi = 24.0;
  int _steps = 8000;
  double _sleepHours = 7.0;
  double _heartRisk = 25.0;
  int _stressScore = 35;

  @override
  void dispose() {
    _messageController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _generateRecommendations() async {
    setState(() {
      _isLoading = true;
      _showRecommendations = false;
    });

    final result = await _copilotService.getPersonalizedRecommendations(
      userId: 'demo_user',
      bmi: _bmi,
      steps: _steps,
      sleepHours: _sleepHours,
      heartRisk: _heartRisk,
      stressScore: _stressScore,
      symptoms: _symptomsController.text.isEmpty ? null : _symptomsController.text,
    );

    setState(() {
      _recommendations = result;
      _isLoading = false;
      _showRecommendations = true;
    });
  }

  Future<void> _sendChat() async {
    if (_messageController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    final response = await _copilotService.chat(_messageController.text);
    
    setState(() {
      _recommendations = response;
      _isLoading = false;
      _showRecommendations = true;
    });
    
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(width),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    children: [
                      _buildHealthInputsCard(width),
                      SizedBox(height: width * 0.04),
                      _buildChatInputCard(width),
                      SizedBox(height: width * 0.04),
                      if (_isLoading) _buildLoadingIndicator(),
                      if (_showRecommendations) _buildRecommendationsCard(width),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: width * 0.06),
            ),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Health Copilot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("🤖 AI Powered", style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("💬 Conversational", style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInputsCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Health Profile", style: TextStyle(color: Colors.white, fontSize: width * 0.04, fontWeight: FontWeight.bold)),
          SizedBox(height: width * 0.03),
          TextField(
            controller: _symptomsController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter symptoms (optional)",
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          SizedBox(height: width * 0.03),
          _buildSliderInput("BMI", _bmi, 15, 40, (v) => setState(() => _bmi = v), "%.1f"),
          _buildSliderInput("Steps", _steps.toDouble(), 0, 20000, (v) => setState(() => _steps = v.round()), "%.0f"),
          _buildSliderInput("Sleep (hrs)", _sleepHours, 0, 12, (v) => setState(() => _sleepHours = v), "%.1f"),
          _buildSliderInput("Heart Risk %", _heartRisk, 0, 100, (v) => setState(() => _heartRisk = v), "%.0f"),
          _buildSliderInput("Stress %", _stressScore.toDouble(), 0, 100, (v) => setState(() => _stressScore = v.round()), "%.0f"),
          SizedBox(height: width * 0.03),
          GestureDetector(
            onTap: _generateRecommendations,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(width * 0.035),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.purple),
                  SizedBox(width: 8),
                  Text("Get AI Recommendations", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderInput(String label, double value, double min, double max, Function(double) onChanged, String format) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(format == "%.0f" ? "${value.round()}" : value.toStringAsFixed(format == "%.1f" ? 1 : 0), style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.cyan,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.cyan,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildChatInputCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask me anything about your health...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendChat(),
            ),
          ),
          GestureDetector(
            onTap: _sendChat,
            child: Container(
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.send, color: Colors.purple, size: width * 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 10),
          Text("Analyzing your health data...", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.tips_and_updates, color: Colors.white, size: width * 0.05),
              ),
              SizedBox(width: 10),
              Text("AI Recommendations", style: TextStyle(color: Colors.white, fontSize: width * 0.04, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: width * 0.03),
          Text(_recommendations, style: TextStyle(color: Colors.white70, fontSize: width * 0.032, height: 1.6)),
        ],
      ),
    );
  }
}
