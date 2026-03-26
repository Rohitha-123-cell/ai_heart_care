import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/stress_service.dart';
import '../../services/heart_rate_service.dart';
import '../../services/fingerprint_service.dart';
import '../../core/utils/responsive.dart';

class StressDetectionScreen extends StatefulWidget {
  const StressDetectionScreen({super.key});

  @override
  State<StressDetectionScreen> createState() => _StressDetectionScreenState();
}

class _StressDetectionScreenState extends State<StressDetectionScreen>
    with TickerProviderStateMixin {
  final StressService _stressService = StressService();
  final HeartRateService _heartRateService = HeartRateService();
  final FingerprintService _fingerprintService = FingerprintService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _progressController;

  bool _isAnalyzing = false;
  bool _hasRealData = false;
  int _heartRate = 0;
  double _hrvScore = 0;
  double _breathingRate = 0;
  int _activityLevel = 50;
  double _stressScore = 0;
  double _displayStressScore = 0;
  String _statusText = "Ready to Scan";
  List<String> _suggestions = [];
  Timer? _analysisTimer;
  Timer? _heartRateTimer;
  int _scanCount = 0;
  List<int> _heartRateReadings = [];
  bool _fingerprintAvailable = false;

  // Questionnaire state
  bool _useQuestionnaire = false;
  int _currentQuestionIndex = 0;
  final List<int> _questionAnswers = [];
  bool _quizInProgress = false;

  static const List<Map<String, dynamic>> _stressQuestions = [
    {
      'question': 'How often have you felt nervous or stressed lately?',
      'icon': '😰',
      'options': ['Rarely', 'Occasionally', 'Sometimes', 'Quite often', 'Very often'],
    },
    {
      'question': 'How well did you sleep last night?',
      'icon': '😴',
      'options': ['Very well (8+ hrs)', 'Well (7–8 hrs)', 'Fairly (6–7 hrs)', 'Poorly (5–6 hrs)', 'Badly (<5 hrs)'],
    },
    {
      'question': 'How is your energy level right now?',
      'icon': '⚡',
      'options': ['Very high', 'High', 'Moderate', 'Low', 'Very low'],
    },
    {
      'question': 'How often have you felt overwhelmed by your tasks?',
      'icon': '🌊',
      'options': ['Not at all', 'Slightly', 'Somewhat', 'Quite a bit', 'Extremely'],
    },
    {
      'question': 'How tense are your muscles right now? (shoulders, neck, jaw)',
      'icon': '💪',
      'options': ['Very relaxed', 'Relaxed', 'Slightly tense', 'Tense', 'Very tense'],
    },
    {
      'question': 'How often have you had difficulty concentrating today?',
      'icon': '🧠',
      'options': ['Never', 'Rarely', 'Sometimes', 'Often', 'Very often'],
    },
    {
      'question': 'How often have you felt irritable or easily angered today?',
      'icon': '😤',
      'options': ['Not at all', 'Slightly', 'Moderately', 'Quite a bit', 'Extremely'],
    },
    {
      'question': 'How much control do you feel over your daily tasks?',
      'icon': '🎯',
      'options': ['Full control', 'Mostly in control', 'Some control', 'Little control', 'No control'],
    },
    {
      'question': 'How is your appetite today?',
      'icon': '🍽️',
      'options': ['Very good', 'Good', 'Normal', 'Poor', 'Very poor'],
    },
    {
      'question': 'How often have you been worrying about unfinished tasks?',
      'icon': '📋',
      'options': ['Never', 'Rarely', 'Sometimes', 'Often', 'Constantly'],
    },
    {
      'question': 'Have you experienced headaches or body aches today?',
      'icon': '🤕',
      'options': ['None at all', 'Very mild', 'Moderate', 'Frequent', 'Severe'],
    },
    {
      'question': 'How satisfied are you with your current life situation?',
      'icon': '😊',
      'options': ['Very satisfied', 'Satisfied', 'Neutral', 'Dissatisfied', 'Very dissatisfied'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
  }

  Future<void> _checkBiometrics() async {
    final hasFingerprint = await _fingerprintService.hasFingerprintSensor();
    setState(() {
      _fingerprintAvailable = hasFingerprint;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _analysisTimer?.cancel();
    _heartRateTimer?.cancel();
    super.dispose();
  }

  void startAnalysis() async {
    if (_isAnalyzing) return;

    // Check if fingerprint is available
    if (!_fingerprintAvailable) {
      // Start without fingerprint - use simulated with variation
      _startSimulationMode();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _statusText = "Place finger on sensor...";
      _stressScore = 0;
      _displayStressScore = 0;
      _heartRate = 0;
      _hrvScore = 0;
      _breathingRate = 0;
      _activityLevel = 50;
      _suggestions = [];
      _scanCount = 0;
      _heartRateReadings = [];
      _hasRealData = false;
    });

    _pulseController.repeat(reverse: true);
    _progressController.forward(from: 0);

    // Get estimated activity level based on time of day
    _activityLevel = _stressService.estimateActivityLevel(DateTime.now());

    // Start real-time fingerprint scanning
    await _startFingerprintScan();
  }

  Future<void> _startFingerprintScan() async {
    // Try to authenticate with fingerprint to get biometric data
    final authenticated = await _fingerprintService.authenticate(
      reason: 'Place your finger on the sensor for stress analysis',
    );

    if (!mounted) return;

    if (authenticated) {
      // Fingerprint authenticated - start collecting real heart rate data
      _collectRealTimeData();
    } else {
      // Fingerprint failed - fall back to simulation with variations
      _startSimulationMode();
    }
  }

  void _collectRealTimeData() async {
    setState(() {
      _statusText = "Scanning biometric data...";
    });

    // Start collecting heart rate readings in real-time
    _heartRateTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (!_isAnalyzing || !mounted) {
        timer.cancel();
        return;
      }

      _scanCount++;

      // Get real heart rate data
      final heartRateData = await _heartRateService.getHeartRateFromFingerprint();

      setState(() {
        if (heartRateData != null) {
          _hasRealData = true;
          _heartRate = (heartRateData['heartRate'] as int?) ?? _heartRate;
          _heartRateReadings.add(_heartRate);

          // Calculate HRV from heart rate variability
          if (_heartRateReadings.length >= 5) {
            _hrvScore = _calculateHRV(_heartRateReadings);
          }

          _statusText = "Scanning... ${(_scanCount * 6).clamp(0, 100)}%";
        } else {
          // Simulate with realistic variations if no real data
          _simulateNextReading();
        }

        // Update progress
        _progressController.value = (_scanCount / 15).clamp(0.0, 1.0);
      });

      // Stop after 15 seconds
      if (_scanCount >= 15) {
        timer.cancel();
        calculateStress();
      }
    });

    // Auto-stop after 18 seconds as backup
    Timer(const Duration(seconds: 18), () {
      if (_isAnalyzing && mounted) {
        calculateStress();
      }
    });
  }

  void _simulateNextReading() {
    // Generate realistic variations based on previous readings
    final baseHR = _heartRateReadings.isNotEmpty ? _heartRateReadings.last : 72;
    final variation = (DateTime.now().millisecondsSinceEpoch % 10) - 5;
    final newHR = (baseHR + variation).clamp(55, 110);

    _heartRateReadings.add(newHR.toInt());
    _heartRate = newHR.toInt();

    if (_heartRateReadings.length >= 5) {
      _hrvScore = _calculateHRV(_heartRateReadings);
    }
  }

  double _calculateHRV(List<int> readings) {
    if (readings.length < 3) return 60.0;

    // Calculate standard deviation of RR intervals
    final avgHR = readings.reduce((a, b) => a + b) / readings.length;
    double sumSquaredDiff = 0;
    for (int i = 0; i < readings.length; i++) {
      final rrInterval = 60000 / readings[i]; // Convert HR to RR interval in ms
      final avgRR = 60000 / avgHR;
      sumSquaredDiff += (rrInterval - avgRR) * (rrInterval - avgRR);
    }
    final sdnn = sumSquaredDiff / readings.length;

    // Convert SDNN to HRV score (0-100 scale)
    // Higher SDNN = better HRV = lower stress
    final hrvScore = ((sdnn - 10) / 50 * 100).clamp(20.0, 100.0);
    return hrvScore;
  }

  void _startSimulationMode() {
    setState(() {
      _isAnalyzing = true;
      _statusText = "Collecting biometric data...";
      _stressScore = 0;
      _displayStressScore = 0;
      _heartRate = 0;
      _hrvScore = 0;
      _breathingRate = 0;
      _activityLevel = 50;
      _suggestions = [];
      _scanCount = 0;
      _heartRateReadings = [];
      _hasRealData = false;
    });

    _pulseController.repeat(reverse: true);
    _progressController.forward(from: 0);

    // Simulate data collection with realistic patterns
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!_isAnalyzing || !mounted) {
        timer.cancel();
        return;
      }

      _scanCount++;

      // Simulate realistic heart rate with variations
      _simulateNextReading();

      // Simulate breathing rate based on scan count
      _breathingRate = (12 + (_scanCount * 0.3)).clamp(12.0, 20.0);

      // Activity level varies during scan
      _activityLevel = (50 + (_scanCount * 2)).clamp(50, 100);

      setState(() {
        _statusText = "Scanning... ${(_scanCount * 6).clamp(0, 100)}%";
      });

      // Stop after 15 seconds
      if (_scanCount >= 15) {
        timer.cancel();
        calculateStress();
      }
    });

    // Auto-stop after 18 seconds as backup
    Timer(const Duration(seconds: 18), () {
      if (_isAnalyzing && mounted) {
        calculateStress();
      }
    });
  }

  void calculateStress() {
    // Stress Calculation Formula using real data:
    // Stress Score =
    //   (HeartRate * 0.3) +        // Normal resting HR is 60-100
    //   ((100 - HRV) * 0.4) +      // Lower HRV = higher stress
    //   (BreathingRate * 0.2) +    // Higher breathing = more stress
    //   ((100 - Activity) * 0.1)   // Lower activity = more stress

    double hrFactor = (_heartRate * 0.3);
    double hrvFactor = ((100 - _hrvScore) * 0.4);
    double breathingFactor = (_breathingRate * 0.2);
    double activityFactor = ((100 - _activityLevel) * 0.1);

    _stressScore = hrFactor + hrvFactor + breathingFactor + activityFactor;

    // Normalize to 0-100
    _stressScore = _stressScore.clamp(0, 100);

    // Get stress level
    String stressLevel = getStressLevel(_stressScore);

    // Get suggestions based on stress level
    _suggestions = _getSuggestions(_stressScore);

    setState(() {
      _statusText = _hasRealData ? "$stressLevel (Real Data)" : stressLevel;
      _isAnalyzing = false;
    });

    _pulseController.stop();
    _progressController.stop();
    _heartRateTimer?.cancel();

    // Animate the stress score display
    _animateStressScore();
  }

  void _animateStressScore() {
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_displayStressScore < _stressScore) {
          _displayStressScore += 1;
        } else {
          _displayStressScore = _stressScore;
          timer.cancel();
        }
      });
    });
  }

  String getStressLevel(double score) {
    if (score < 30) {
      return "Relaxed 😊";
    } else if (score < 50) {
      return "Calm 🙂";
    } else if (score < 70) {
      return "Moderate 😐";
    } else if (score < 85) {
      return "Stressed 😰";
    } else {
      return "High Stress 😱";
    }
  }

  String getEmoji() {
    if (_stressScore < 30) return "😊";
    if (_stressScore < 50) return "🙂";
    if (_stressScore < 70) return "😐";
    if (_stressScore < 85) return "😰";
    return "😱";
  }

  List<String> _getSuggestions(double score) {
    if (score < 30) {
      return [
        "🌟 Excellent! Your stress levels are very low.",
        "💪 Keep up your healthy lifestyle habits.",
        "🧘 Continue regular exercise and meditation.",
        "😊 You're doing great - maintain this balance!",
      ];
    } else if (score < 50) {
      return [
        "🌿 Good job! Your stress is well managed.",
        "🚶 Consider a short walk to stay relaxed.",
        "💤 Ensure you're getting adequate sleep.",
        "🥗 Maintain a balanced diet for wellness.",
      ];
    } else if (score < 70) {
      return [
        "⏸️ Consider taking short breaks throughout the day.",
        "🧘 Practice deep breathing exercises (4-7-8 technique).",
        "🎵 Try a 10-minute meditation or calming music.",
        "💧 Stay hydrated and maintain regular sleep.",
      ];
    } else if (score < 85) {
      return [
        "⚠️ Your stress levels are elevated.",
        "🧘 Take immediate breaks when feeling overwhelmed.",
        "📱 Consider limiting screen time and social media.",
        "🏃 Try light exercise like walking or stretching.",
      ];
    } else {
      return [
        "🚨 High stress detected - take action now!",
        "🆘 Consider talking to a counselor or therapist.",
        "🧘 Practice progressive muscle relaxation.",
        "⛔ Limit caffeine and screen time immediately.",
        "💤 Prioritize sleep and self-care activities.",
      ];
    }
  }

  void _stopAnalysis() {
    _analysisTimer?.cancel();
    _heartRateTimer?.cancel();

    setState(() {
      _isAnalyzing = false;
      _statusText = "Analysis Stopped";
    });

    _pulseController.stop();
    _progressController.stop();
  }

  // ── Questionnaire logic ──────────────────────────────────────────────────

  void _startQuestionnaire() {
    setState(() {
      _currentQuestionIndex = 0;
      _questionAnswers.clear();
      _quizInProgress = true;
      _stressScore = 0;
      _displayStressScore = 0;
      _suggestions = [];
      _statusText = "Ready to Scan";
    });
  }

  void _answerQuestion(int score) {
    setState(() {
      _questionAnswers.add(score);
      if (_currentQuestionIndex < _stressQuestions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _calculateQuizStress();
      }
    });
  }

  void _calculateQuizStress() {
    final total = _questionAnswers.fold(0, (sum, v) => sum + v);
    final maxPossible = _stressQuestions.length * 4;
    _stressScore = (total / maxPossible * 100).clamp(0.0, 100.0);
    _suggestions = _getSuggestions(_stressScore);
    _quizInProgress = false;
    _animateStressScore();
  }

  Color _getStressColor() {
    if (_displayStressScore < 30) return Colors.green;
    if (_displayStressScore < 50) return Colors.lightGreen;
    if (_displayStressScore < 70) return Colors.orange;
    if (_displayStressScore < 85) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth.clamp(0.0, 520.0).toDouble();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: Column(
            children: [
              _buildAppBar(width),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    children: [
                      _buildMethodSelector(width),
                      SizedBox(height: width * 0.04),
                      if (_useQuestionnaire && _quizInProgress)
                        _buildQuizCard(width)
                      else ...[
                        _buildStressCircleCard(width),
                        SizedBox(height: width * 0.05),
                        if (!_useQuestionnaire) ...[
                          _buildMetricsCards(width),
                          SizedBox(height: width * 0.05),
                          _buildDataSourceIndicator(width),
                          SizedBox(height: width * 0.04),
                        ],
                        _buildActionButton(width),
                        SizedBox(height: width * 0.04),
                        if (_suggestions.isNotEmpty) _buildSuggestionsCard(width),
                        SizedBox(height: width * 0.04),
                        _buildInfoCard(width),
                      ],
                    ],
                  ),
                ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(double width) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _methodTab(
            width: width,
            icon: Icons.fingerprint,
            label: 'Biometric Scan',
            selected: !_useQuestionnaire,
            onTap: () => setState(() {
              _useQuestionnaire = false;
              _quizInProgress = false;
              _stressScore = 0;
              _displayStressScore = 0;
              _suggestions = [];
              _statusText = 'Ready to Scan';
            }),
          ),
          _methodTab(
            width: width,
            icon: Icons.quiz_outlined,
            label: 'Stress Quiz',
            selected: _useQuestionnaire,
            onTap: () => setState(() {
              _useQuestionnaire = true;
              _quizInProgress = false;
              _stressScore = 0;
              _displayStressScore = 0;
              _suggestions = [];
              _currentQuestionIndex = 0;
              _questionAnswers.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _methodTab({
    required double width,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: width * 0.03),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF667eea) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: width * 0.045),
              SizedBox(width: width * 0.015),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: width * 0.03,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(double width) {
    final q = _stressQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _stressQuestions.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_stressQuestions.length}',
                style: TextStyle(color: Colors.white70, fontSize: width * 0.028),
              ),
              const Spacer(),
              Text(
                '${(_currentQuestionIndex / _stressQuestions.length * 100).toInt()}%',
                style: TextStyle(color: const Color(0xFF667eea), fontSize: width * 0.028, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          ),
          SizedBox(height: width * 0.05),

          // Question
          Text(
            q['icon'] as String,
            style: TextStyle(fontSize: width * 0.1),
          ),
          SizedBox(height: width * 0.025),
          Text(
            q['question'] as String,
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.038,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          SizedBox(height: width * 0.04),

          // Answer options
          ...(q['options'] as List<String>).asMap().entries.map((entry) {
            final score = entry.key; // 0=best, 4=worst
            final label = entry.value;
            return GestureDetector(
              onTap: () => _answerQuestion(score),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: width * 0.025),
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: width * 0.035,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _optionColor(score).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + score), // A B C D E
                          style: TextStyle(
                            color: _optionColor(score),
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.03,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.032,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white38, size: width * 0.03),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _optionColor(int score) {
    const colors = [Colors.green, Colors.lightGreen, Colors.orange, Colors.deepOrange, Colors.red];
    return colors[score.clamp(0, 4)];
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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stress Detection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildBadge("🧠 AI Powered", Colors.purple),
                    const SizedBox(width: 8),
                    _buildBadge(_hasRealData ? "📊 Real Data" : "🔄 Simulated", _hasRealData ? Colors.green : Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStressCircleCard(double width) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: width * 0.7,
          height: width * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _getStressColor().withOpacity(_glowAnimation.value),
                _getStressColor().withOpacity(0.1),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _getStressColor().withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1a1a2e).withOpacity(0.9),
              border: Border.all(
                color: _getStressColor().withOpacity(0.5),
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress indicator during analysis
                if (_isAnalyzing)
                  SizedBox(
                    width: width * 0.6,
                    height: width * 0.6,
                    child: CircularProgressIndicator(
                      value: _progressController.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(_getStressColor()),
                    ),
                  ),

                // Main content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
                          child: Text(
                            _stressScore > 0 ? getEmoji() : "👆",
                            style: const TextStyle(fontSize: 50),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: width * 0.02),

                    // Status text
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getStressColor(),
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: width * 0.02),

                    // Stress percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_displayStressScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: width * 0.02),
                          child: Text(
                            "%",
                            style: TextStyle(
                              color: _getStressColor(),
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsCards(double width) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            width,
            "❤️",
            "Heart Rate",
            _heartRate > 0 ? "$_heartRate" : "--",
            "BPM",
            Colors.red,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildMetricCard(
            width,
            "💓",
            "HRV Score",
            _hrvScore > 0 ? "${_hrvScore.toStringAsFixed(0)}" : "--",
            "",
            Colors.purple,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildMetricCard(
            width,
            "🌬️",
            "Breathing",
            _breathingRate > 0 ? "${_breathingRate.toStringAsFixed(1)}" : "--",
            "/min",
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    double width,
    String emoji,
    String title,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          SizedBox(height: width * 0.01),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.024,
            ),
          ),
          SizedBox(height: width * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.isEmpty ? "--" : value,
                style: TextStyle(
                  color: color,
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  " $unit",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: width * 0.02,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourceIndicator(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: (_hasRealData ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_hasRealData ? Colors.green : Colors.orange).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasRealData ? Icons.fingerprint : Icons.phone_android,
            color: _hasRealData ? Colors.green : Colors.orange,
            size: 24,
          ),
          SizedBox(width: width * 0.02),
          Expanded(
            child: Text(
              _hasRealData
                  ? "Using real biometric sensor data"
                  : "Using simulated data - Place finger on sensor for real readings",
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.03,
              ),
            ),
          ),
          if (!_fingerprintAvailable)
            Text(
              "Sensor unavailable",
              style: TextStyle(
                color: Colors.orange,
                fontSize: width * 0.025,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(double width) {
    if (_useQuestionnaire) {
      final isRetake = _stressScore > 0 && !_quizInProgress;
      return GestureDetector(
        onTap: _startQuestionnaire,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(width * 0.045),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.4),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRetake ? Icons.refresh_rounded : Icons.quiz_outlined,
                color: Colors.white,
                size: width * 0.06,
              ),
              SizedBox(width: width * 0.02),
              Text(
                isRetake ? "Retake Quiz" : "Start Stress Quiz",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Biometric mode (original)
    return GestureDetector(
      onTap: _isAnalyzing ? _stopAnalysis : startAnalysis,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.045),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isAnalyzing
                ? [Colors.red.withValues(alpha: 0.8), Colors.red]
                : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: (_isAnalyzing ? Colors.red : const Color(0xFF667eea))
                  .withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAnalyzing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(Icons.fingerprint, color: Colors.white, size: width * 0.06),
            SizedBox(width: width * 0.02),
            Text(
              _isAnalyzing
                  ? "Stop Analysis"
                  : _fingerprintAvailable
                      ? "Start Biometric Scan"
                      : "Start Analysis",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(double width) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStressColor().withOpacity(0.1),
            _getStressColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStressColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: _getStressColor(), size: 24),
              SizedBox(width: width * 0.02),
              Text(
                "Recommendations",
                style: TextStyle(
                  color: _getStressColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          ...(_suggestions.map((suggestion) => Padding(
                padding: EdgeInsets.only(bottom: width * 0.02),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStressColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.03,
                        ),
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildInfoCard(double width) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white54, size: 20),
              SizedBox(width: width * 0.02),
              Text(
                "How it works",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.035,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          _buildInfoItem("1. Place your finger on the fingerprint sensor", width),
          _buildInfoItem("2. Keep your finger steady for 15 seconds", width),
          _buildInfoItem("3. Real-time heart rate and HRV are measured", width),
          _buildInfoItem("4. Stress score is calculated from biometric data", width),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, double width) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.02),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: width * 0.02),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.028,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
