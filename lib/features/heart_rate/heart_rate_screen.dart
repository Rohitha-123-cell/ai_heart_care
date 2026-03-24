import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/heart_rate_service.dart';
import '../hospitals/map_screen.dart';
import '../emergency/emergency_screen.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen>
    with TickerProviderStateMixin {
  final HeartRateService _heartRateService = HeartRateService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late AnimationController _countdownController;
  late AnimationController _glowController;

  bool _isMeasuring = false;
  int _currentBPM = 0;
  int _displayBPM = 0;
  String _heartStatus = "Ready to measure";
  List<int> _bpmHistory = [];
  int _secondsRemaining = 15;
  int _elapsedSeconds = 0;
  
  bool _fingerDetected = false;
  int? _currentRedIntensity;
  int _signalQuality = 0;
  
  List<int> _samples = [];
  List<DateTime> _timestamps = [];
  Timer? _captureTimer;
  Timer? _countdownTimer;
  Timer? _displayTimer;

  int _measurementMode = 0;
  final TextEditingController _bpmController = TextEditingController();

  // ============ HEALTH METRICS ============
  int _heartRate = 72;
  int _systolic = 120;
  int _diastolic = 80;
  int _spO2 = 98;
  double _temperature = 36.6;
  int _steps = 8000;
  int _caloriesBurned = 320;

  double _sleepHours = 7.5;
  String _sleepQuality = 'Good';
  double _waterIntake = 1.5;
  String _foodType = 'Mixed';
  String _stressLevel = 'Low';
  String _stressEmoji = '😊';

  int _healthScore = 85;
  String _healthRisk = 'Low';
  String _dailyTip = '🌟 Stay hydrated and keep moving!';

  final TextEditingController _hrController = TextEditingController(text: '72');
  final TextEditingController _sysController = TextEditingController(text: '120');
  final TextEditingController _diaController = TextEditingController(text: '80');
  final TextEditingController _spo2Controller = TextEditingController(text: '98');
  final TextEditingController _tempController = TextEditingController(text: '36.6');
  final TextEditingController _stepsController = TextEditingController(text: '8000');
  final TextEditingController _sleepController = TextEditingController(text: '7.5');
  final TextEditingController _waterController = TextEditingController(text: '1.5');

  bool _isDarkMode = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
    _calculateHealthMetrics();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _countdownController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isCameraPermissionGranted = true);
      await _setupCamera();
    } else {
      setState(() => _heartStatus = "Camera permission required");
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final backCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      print('Camera error: $e');
      setState(() => _heartStatus = "Camera error: $e");
    }
  }

  void _calculateHealthMetrics() {
    setState(() {
      _heartRate = int.tryParse(_hrController.text) ?? 72;
      _systolic = int.tryParse(_sysController.text) ?? 120;
      _diastolic = int.tryParse(_diaController.text) ?? 80;
      _spO2 = int.tryParse(_spo2Controller.text) ?? 98;
      _temperature = double.tryParse(_tempController.text) ?? 36.6;
      _steps = int.tryParse(_stepsController.text) ?? 8000;
      _sleepHours = double.tryParse(_sleepController.text) ?? 7.5;
      _waterIntake = double.tryParse(_waterController.text) ?? 1.5;

      _caloriesBurned = (_steps * 0.04).round();
      _sleepQuality = _sleepHours >= 7 ? 'Good' : 'Poor';
      
      int score = 100;
      if (_heartRate < 60 || _heartRate > 100) score -= 15;
      if (_systolic > 140 || _diastolic > 90) score -= 20;
      if (_spO2 < 95) score -= 15;
      if (_temperature < 36.1 || _temperature > 37.2) score -= 10;
      if (_steps < 5000) score -= 10;
      if (_sleepHours < 6) score -= 15;
      if (_waterIntake < 1.5) score -= 5;
      _healthScore = score.clamp(0, 100);

      if (_healthScore >= 70) {
        _healthRisk = 'Low';
      } else if (_healthScore >= 40) {
        _healthRisk = 'Medium';
      } else {
        _healthRisk = 'High';
      }

      if (_heartRate < 80 && _sleepHours >= 7) {
        _stressLevel = 'Low';
        _stressEmoji = '😊';
      } else if (_heartRate < 100) {
        _stressLevel = 'Medium';
        _stressEmoji = '😐';
      } else {
        _stressLevel = 'High';
        _stressEmoji = '😰';
      }

      List<String> tips = [];
      if (_steps < 10000) tips.add('Reach 10,000 steps today!');
      if (_waterIntake < 2.0) tips.add('Drink more water!');
      if (_sleepHours < 7) tips.add('Get more sleep tonight.');
      if (_heartRate > 90) tips.add('Try deep breathing exercises.');
      if (tips.isEmpty) {
        tips.add('🌟 Great job! Keep up your healthy habits!');
      }
      _dailyTip = tips.first;
    });
  }

  Color _getHealthScoreColor() {
    if (_healthScore >= 70) return Colors.green;
    if (_healthScore >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getRiskColor() {
    switch (_healthRisk) {
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getStressColor() {
    switch (_stressLevel) {
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _stopMeasurement();
    _pulseController.dispose();
    _waveController.dispose();
    _countdownController.dispose();
    _glowController.dispose();
    _cameraController?.dispose();
    _bpmController.dispose();
    _hrController.dispose();
    _sysController.dispose();
    _diaController.dispose();
    _spo2Controller.dispose();
    _tempController.dispose();
    _stepsController.dispose();
    _sleepController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _startMeasurement() async {
    if (_isMeasuring) return;
    
    if (_measurementMode == 1) {
      _startManualInput();
      return;
    } else if (_measurementMode == 2) {
      _startDemoMode();
      return;
    }

    if (!_isCameraInitialized || _cameraController == null) {
      _showError("Camera not available");
      return;
    }

    try {
      await _cameraController!.setFlashMode(FlashMode.torch);
    } catch (e) {
      print('Flashlight error: $e');
    }

    setState(() {
      _isMeasuring = true;
      _currentBPM = 0;
      _displayBPM = 0;
      _bpmHistory = [];
      _heartStatus = "Place finger on camera...";
      _secondsRemaining = 15;
      _elapsedSeconds = 0;
      _fingerDetected = false;
      _currentRedIntensity = null;
      _signalQuality = 0;
      _samples = [];
      _timestamps = [];
    });

    _pulseController.repeat(reverse: true);
    _countdownController.forward(from: 0);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMeasuring) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _secondsRemaining--;
        _elapsedSeconds++;
      });

      if (_secondsRemaining <= 0) {
        timer.cancel();
        _completeMeasurement();
      }
    });

    _captureTimer = Timer.periodic(
      Duration(milliseconds: HeartRateService.sampleRateMs),
      (timer) => _captureFrame(),
    );

    _displayTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isMeasuring) {
        timer.cancel();
        return;
      }
      
      if (_samples.length >= 50) {
        int? realtimeBPM = _heartRateService.processSamples(_samples, _timestamps);
        if (realtimeBPM != null && _heartRateService.isValidBPM(realtimeBPM)) {
          setState(() {
            _currentBPM = realtimeBPM;
            _bpmHistory.add(realtimeBPM);
            _heartStatus = _heartRateService.analyzeHeartRate(realtimeBPM);
            _hrController.text = realtimeBPM.toString();
            _calculateHealthMetrics();
          });
        }
      }
      
      setState(() {
        if (_displayBPM != _currentBPM) {
          _displayBPM = _currentBPM;
        }
      });
    });
  }

  Future<void> _captureFrame() async {
    if (!_isMeasuring || _cameraController == null) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      int? redIntensity = _heartRateService.analyzeFrame(bytes, 320, 240);
      
      if (redIntensity != null) {
        bool wasDetected = _fingerDetected;
        setState(() {
          _currentRedIntensity = redIntensity;
          _fingerDetected = _heartRateService.isFingerDetected(redIntensity);
          
          if (_fingerDetected) {
            _samples.add(redIntensity);
            _timestamps.add(DateTime.now());
            _signalQuality = _heartRateService.getSignalQuality(_samples);
            _heartStatus = _heartRateService.getFingerStatus(redIntensity);
            
            if (!wasDetected) {
              HapticFeedback.mediumImpact();
            }
          } else {
            _heartStatus = _heartRateService.getFingerStatus(redIntensity);
            
            if (wasDetected && _samples.length > 10) {
              HapticFeedback.heavyImpact();
            }
          }
        });

        if (_fingerDetected == false && _samples.length > 30) {
          _stopMeasurement();
          _showError("Finger removed! Please try again.");
        }
      }
    } catch (e) {
      print('Frame capture error: $e');
    }
  }

  void _completeMeasurement() {
    _stopMeasurement();
    
    int? finalBPM;
    if (_samples.length >= 30) {
      finalBPM = _heartRateService.processSamples(_samples, _timestamps);
    }
    
    if (finalBPM != null && _heartRateService.isValidBPM(finalBPM)) {
      setState(() {
        _displayBPM = finalBPM!;
        _heartStatus = _heartRateService.analyzeHeartRate(finalBPM);
        _hrController.text = finalBPM.toString();
        _calculateHealthMetrics();
      });
      _showResultDialog(finalBPM);
    } else {
      setState(() {
        _heartStatus = "Could not detect heart rate. Try again.";
      });
      _showError("Could not detect heart rate. Please try again with better lighting.");
    }
  }

  void _stopMeasurement() {
    _captureTimer?.cancel();
    _countdownTimer?.cancel();
    _displayTimer?.cancel();
    _pulseController.stop();
    _countdownController.stop();
    
    try {
      _cameraController?.setFlashMode(FlashMode.off);
    } catch (e) {
      print('Flashlight off error: $e');
    }

    setState(() {
      _isMeasuring = false;
      if (_bpmHistory.isEmpty) {
        _heartStatus = "Ready to measure";
      }
    });
  }

  void _startManualInput() {
    final input = _bpmController.text.trim();
    if (input.isEmpty) {
      _showError("Please enter your heart rate");
      return;
    }

    final bpm = int.tryParse(input);
    if (bpm == null || !_heartRateService.isValidBPM(bpm)) {
      _showError("Enter valid heart rate (30-220 BPM)");
      return;
    }

    setState(() {
      _currentBPM = bpm;
      _displayBPM = bpm;
      _bpmHistory.add(bpm);
      _heartStatus = _heartRateService.analyzeHeartRate(bpm);
      _hrController.text = bpm.toString();
      _calculateHealthMetrics();
    });

    _bpmController.clear();
    HapticFeedback.mediumImpact();
    _showResultDialog(bpm);
  }

  void _startDemoMode() {
    setState(() {
      _isMeasuring = true;
      _currentBPM = 0;
      _displayBPM = 0;
      _bpmHistory = [];
      _heartStatus = "Measuring heart rate...";
      _secondsRemaining = 15;
    });

    _pulseController.repeat(reverse: true);

    int tickCount = 0;
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isMeasuring) {
        timer.cancel();
        return;
      }

      tickCount++;
      final random = math.Random();
      int baseHR = _bpmHistory.isNotEmpty ? _bpmHistory.last : 72;
      int variation = random.nextInt(12) - 6;
      int simulatedBPM = (baseHR + variation).clamp(55, 95);
      
      if (random.nextDouble() < 0.1) {
        simulatedBPM += random.nextInt(15);
      }

      setState(() {
        _currentBPM = simulatedBPM;
        _displayBPM = simulatedBPM;
        _bpmHistory.add(simulatedBPM);
        _secondsRemaining = 15 - (tickCount ~/ 2);
        _heartStatus = _heartRateService.analyzeHeartRate(simulatedBPM);
        _hrController.text = simulatedBPM.toString();
      });

      HapticFeedback.lightImpact();

      if (tickCount >= 30) {
        timer.cancel();
        _completeDemo();
      }
    });
  }

  void _completeDemo() {
    _stopMeasurement();
    _calculateHealthMetrics();
    int avgBPM = _getAverageBPM();
    if (avgBPM > 0) {
      setState(() {
        _displayBPM = avgBPM;
        _heartStatus = "Demo complete!";
      });
      _showResultDialog(avgBPM, isDemo: true);
    }
  }

  void _showResultDialog(int bpm, {bool isDemo = false}) {
    String analysis = _heartRateService.analyzeHeartRate(bpm);
    String recommendation = _heartRateService.getRecommendation(bpm);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isDemo ? Icons.science : Icons.check_circle,
              color: isDemo ? Colors.purple : Colors.green,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              isDemo ? 'Demo Complete!' : 'Heart Rate Detected!',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    '$bpm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('BPM', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(analysis, style: const TextStyle(color: Colors.cyan, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(recommendation, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done', style: TextStyle(color: Colors.green, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startMeasurement();
            },
            child: Text(isDemo ? 'Run Again' : 'Measure Again', style: const TextStyle(color: Colors.cyan, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int _getAverageBPM() {
    if (_bpmHistory.isEmpty) return 0;
    return (_bpmHistory.reduce((a, b) => a + b) / _bpmHistory.length).round();
  }

  Color _getBPMColor() {
    if (_displayBPM == 0 && _currentBPM == 0) return Colors.grey;
    final bpm = _displayBPM > 0 ? _displayBPM : _currentBPM;
    return Color(_heartRateService.getHeartRateColor(bpm));
  }

  Widget _buildGlassCard({required Widget child, Color? glowColor}) {
    double width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: glowColor?.withOpacity(0.3 + (_glowController.value * 0.2)) ?? Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(0.2 * _glowController.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460), Color(0xFF1a1a2e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(width),
              _buildTabSelector(width),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    children: [
                      if (_selectedTab == 0) ...[
                        _buildModeSelector(width),
                        const SizedBox(height: 16),
                        if (_measurementMode == 0) _buildCameraSection(width)
                        else if (_measurementMode == 1) _buildManualInputSection(width)
                        else _buildDemoSection(width),
                        const SizedBox(height: 16),
                        _buildHeartDisplay(width),
                        const SizedBox(height: 16),
                        _buildStatusCard(width),
                        const SizedBox(height: 16),
                        _buildActionButton(width),
                        if (_bpmHistory.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildHistoryCard(width),
                        ],
                      ] else ...[
                        _buildHealthDashboard(width),
                      ],
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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Heart Rate Monitor',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildBadge("📷 PPG", _measurementMode == 0 ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    _buildBadge("✏️ Manual", _measurementMode == 1 ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    _buildBadge("🎭 Demo", _measurementMode == 2 ? Colors.green : Colors.grey),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTabSelector(double width) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.04),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: width * 0.025),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 0 
                      ? const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)])
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: _selectedTab == 0 ? Colors.white : Colors.white54, size: 18),
                    const SizedBox(width: 8),
                    Text("Monitor", style: TextStyle(color: _selectedTab == 0 ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: width * 0.025),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 1 
                      ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard, color: _selectedTab == 1 ? Colors.white : Colors.white54, size: 18),
                    const SizedBox(width: 8),
                    Text("Health", style: TextStyle(color: _selectedTab == 1 ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(double width) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _buildModeButton(0, "📷 Camera", width),
          _buildModeButton(1, "✏️ Manual", width),
          _buildModeButton(2, "🎮 Demo", width),
        ],
      ),
    );
  }

  Widget _buildModeButton(int mode, String text, double width) {
    bool isSelected = _measurementMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isMeasuring) return;
          setState(() => _measurementMode = mode);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: width * 0.025),
          decoration: BoxDecoration(
            gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildCameraSection(double width) {
    return _buildGlassCard(
      glowColor: _fingerDetected ? Colors.green : Colors.red,
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _isCameraInitialized && _cameraController != null
                  ? Stack(
                      children: [
                        Transform.scale(scale: 0.5, child: CameraPreview(_cameraController!)),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _fingerDetected ? Icons.check_circle : Icons.fingerprint,
                                color: _fingerDetected ? Colors.green : Colors.white54,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _fingerDetected ? "Finger detected!" : "Place finger here",
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              if (_currentRedIntensity != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Signal: $_currentRedIntensity",
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: _isCameraPermissionGranted
                          ? const CircularProgressIndicator(color: Colors.white54)
                          : const Text("Camera permission required", style: TextStyle(color: Colors.white54)),
                    ),
            ),
          ),
          SizedBox(height: width * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _fingerDetected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _heartStatus,
                style: TextStyle(color: _fingerDetected ? Colors.green : Colors.red.shade300, fontSize: 13),
              ),
            ],
          ),
          if (_samples.isNotEmpty) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _signalQuality / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_signalQuality > 50 ? Colors.green : Colors.orange),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            Text("Signal Quality: $_signalQuality%", style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildManualInputSection(double width) {
    return _buildGlassCard(
      glowColor: Colors.green,
      child: Column(
        children: [
          const Icon(Icons.edit_note, color: Colors.green, size: 40),
          const SizedBox(height: 12),
          const Text("Enter Your Heart Rate", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bpmController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: "72",
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 24),
                      border: InputBorder.none,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(14), bottomRight: Radius.circular(14)),
                  ),
                  child: const Text("BPM", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [60, 65, 72, 80, 90].map((bpm) => GestureDetector(
              onTap: () => _bpmController.text = bpm.toString(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("$bpm", style: const TextStyle(color: Colors.white70)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoSection(double width) {
    return _buildGlassCard(
      glowColor: Colors.purple,
      child: Column(
        children: [
          const Icon(Icons.science, color: Colors.purple, size: 40),
          const SizedBox(height: 12),
          const Text("Demo Mode", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Simulates heart rate detection\nfor testing purposes",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartDisplay(double width) {
    return _buildGlassCard(
      glowColor: _getBPMColor(),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isMeasuring ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: EdgeInsets.all(width * 0.06),
                  decoration: BoxDecoration(
                    color: _getBPMColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getBPMColor().withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.favorite, color: _getBPMColor(), size: width * 0.15),
                ),
              );
            },
          ),
          SizedBox(height: width * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _displayBPM > 0 ? "$_displayBPM" : "--",
                style: TextStyle(color: _getBPMColor(), fontSize: width * 0.15, fontWeight: FontWeight.w800),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: width * 0.015),
                child: Text(" BPM", style: TextStyle(color: Colors.white70, fontSize: width * 0.045)),
              ),
            ],
          ),
          if (_measurementMode == 0 && _isMeasuring) ...[
            SizedBox(height: width * 0.03),
            LinearProgressIndicator(
              value: _secondsRemaining / 15,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_getBPMColor()),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              "Time remaining: $_secondsRemaining sec",
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(double width) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_fingerDetected ? Icons.check_circle : Icons.info_outline, color: _fingerDetected ? Colors.green : Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text("How to Use", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          SizedBox(height: width * 0.03),
          _buildInstructionRow(Icons.fingerprint, "1. Place fingertip COVERING the camera lens completely"),
          _buildInstructionRow(Icons.handyman, "2. Press finger FIRMLY against the camera"),
          _buildInstructionRow(Icons.flashlight_on, "3. The flashlight will turn on automatically"),
          _buildInstructionRow(Icons.timer, "4. Hold still for 15 seconds until measurement completes"),
          _buildInstructionRow(Icons.lightbulb, "5. Ensure good lighting and don't block light"),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "If not working: Try cleaning camera lens, remove thick gloves, or use Manual mode instead",
                    style: TextStyle(color: Colors.amber.shade300, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildActionButton(double width) {
    return GestureDetector(
      onTap: _isMeasuring ? _stopMeasurement : _startMeasurement,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.045),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isMeasuring
                ? [Colors.red.withOpacity(0.8), Colors.red]
                : [const Color(0xFFFF512F), const Color(0xFFDD2476)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isMeasuring ? Colors.red.withOpacity(0.4) : const Color(0xFFFF512F).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isMeasuring ? Icons.stop : Icons.play_arrow, color: Colors.white, size: width * 0.06),
            SizedBox(width: width * 0.02),
            Text(
              _isMeasuring ? "Stop" : "Start Measurement",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: width * 0.04),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(double width) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${_bpmHistory.length} readings", style: const TextStyle(color: Colors.purple, fontSize: 12)),
            ],
          ),
          SizedBox(height: width * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Avg", "${_getAverageBPM()}", Colors.cyan),
              _buildStatItem("Min", "${_bpmHistory.isEmpty ? 0 : _bpmHistory.reduce((a, b) => a < b ? a : b)}", Colors.green),
              _buildStatItem("Max", "${_bpmHistory.isEmpty ? 0 : _bpmHistory.reduce((a, b) => a > b ? a : b)}", Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHealthDashboard(double width) {
    return Column(
      children: [
        _buildHealthScoreCard(width),
        SizedBox(height: width * 0.04),
        _buildEmergencySection(width),
        SizedBox(height: width * 0.04),
        _buildSectionTitle('Vital Signs', Icons.favorite, Colors.red),
        SizedBox(height: width * 0.03),
        _buildCoreMetricsGrid(width),
        SizedBox(height: width * 0.04),
        _buildSectionTitle('Daily Tracking', Icons.trending_up, Colors.cyan),
        SizedBox(height: width * 0.03),
        _buildIntermediateSection(width),
        SizedBox(height: width * 0.04),
        _buildSectionTitle('Mental Wellness', Icons.psychology, Colors.purple),
        SizedBox(height: width * 0.03),
        _buildStressMoodSection(width),
        SizedBox(height: width * 0.04),
        _buildDailyTipsCard(width),
        SizedBox(height: width * 0.04),
        _buildUpdateButton(width),
      ],
    );
  }

  Widget _buildHealthScoreCard(double width) {
    return _buildGlassCard(
      glowColor: _getHealthScoreColor(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF667eea), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Health Score',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(_stressEmoji, style: const TextStyle(fontSize: 32)),
            ],
          ),
          SizedBox(height: width * 0.05),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: width * 0.35,
                  height: width * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _getHealthScoreColor().withOpacity(0.3),
                        _getHealthScoreColor().withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(color: _getHealthScoreColor(), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: _getHealthScoreColor().withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_healthScore',
                        style: TextStyle(color: _getHealthScoreColor(), fontSize: width * 0.12, fontWeight: FontWeight.bold),
                      ),
                      Text('of 100', style: TextStyle(color: Colors.white60, fontSize: width * 0.03)),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: width * 0.04),
          Container(
            padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: width * 0.02),
            decoration: BoxDecoration(
              color: _getHealthScoreColor(),
              borderRadius: BorderRadius.circular(width * 0.08),
            ),
            child: Text(
              _healthScore >= 70 ? 'Excellent' : _healthScore >= 40 ? 'Fair' : 'Needs Attention',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(height: width * 0.04),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat('Heart Risk', _healthRisk, _getRiskColor()),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildMiniStat('Stress', _stressLevel, _getStressColor()),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildMiniStat('Calories', '$_caloriesBurned', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmergencySection(double width) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()));
            },
            child: Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF512F).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 24),
                  SizedBox(width: width * 0.02),
                  const Text('Emergency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
            },
            child: Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFF11998e),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF11998e).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                  SizedBox(width: width * 0.02),
                  const Text('Hospitals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCoreMetricsGrid(double width) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildHeartRateInputCard(width)),
            SizedBox(width: width * 0.03),
            Expanded(child: _buildBloodPressureInputCard(width)),
          ],
        ),
        SizedBox(height: width * 0.03),
        Row(
          children: [
            Expanded(child: _buildSpO2InputCard(width)),
            SizedBox(width: width * 0.03),
            Expanded(child: _buildTemperatureInputCard(width)),
          ],
        ),
        SizedBox(height: width * 0.03),
        _buildStepsInputCard(width),
      ],
    );
  }

  Widget _buildHeartRateInputCard(double width) {
    return _buildGlassCard(
      glowColor: Colors.red,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.favorite, color: Colors.red, size: 28),
          ),
          SizedBox(height: width * 0.02),
          TextField(
            controller: _hrController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '--',
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onChanged: (_) => _calculateHealthMetrics(),
          ),
          const Text('BPM', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBloodPressureInputCard(double width) {
    return _buildGlassCard(
      glowColor: Colors.pink,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.pink.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.speed, color: Colors.pink, size: 28),
          ),
          SizedBox(height: width * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _sysController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '--', hintStyle: TextStyle(color: Colors.white30)),
                  onChanged: (_) => _calculateHealthMetrics(),
                ),
              ),
              const Text('/', style: TextStyle(color: Colors.white54, fontSize: 18)),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _diaController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '--', hintStyle: TextStyle(color: Colors.white30)),
                  onChanged: (_) => _calculateHealthMetrics(),
                ),
              ),
            ],
          ),
          const Text('mmHg', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSpO2InputCard(double width) {
    return _buildGlassCard(
      glowColor: Colors.blue,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.air, color: Colors.blue, size: 28),
          ),
          SizedBox(height: width * 0.02),
          TextField(
            controller: _spo2Controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '--',
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onChanged: (_) => _calculateHealthMetrics(),
          ),
          const Text('% SpO2', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTemperatureInputCard(double width) {
    return _buildGlassCard(
      glowColor: Colors.orange,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.thermostat, color: Colors.orange, size: 28),
          ),
          SizedBox(height: width * 0.02),
          TextField(
            controller: _tempController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '--',
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onChanged: (_) => _calculateHealthMetrics(),
          ),
          const Text('°C', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStepsInputCard(double width) {
    return _buildGlassCard(
      glowColor: Colors.green,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.directions_walk, color: Colors.green, size: 28),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _stepsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '--',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                  onChanged: (_) => _calculateHealthMetrics(),
                ),
                const Text('Steps Today', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$_caloriesBurned', style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('cal', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntermediateSection(double width) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSleepCard(width)),
            SizedBox(width: width * 0.03),
            Expanded(child: _buildWaterCard(width)),
          ],
        ),
        SizedBox(height: width * 0.03),
        _buildFoodCard(width),
      ],
    );
  }

  Widget _buildSleepCard(double width) {
    return _buildGlassCard(
      glowColor: Colors.purple,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.bedtime, color: Colors.purple, size: 28),
          ),
          SizedBox(height: width * 0.02),
          TextField(
            controller: _sleepController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '--',
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onChanged: (_) => _calculateHealthMetrics(),
          ),
          const Text('Hours Sleep', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _sleepQuality == 'Good' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_sleepQuality, style: TextStyle(color: _sleepQuality == 'Good' ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(double width) {
    final progress = (_waterIntake / 2.0).clamp(0.0, 1.0);
    return _buildGlassCard(
      glowColor: Colors.cyan,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.water_drop, color: Colors.cyan, size: 28),
          ),
          SizedBox(height: width * 0.02),
          TextField(
            controller: _waterController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '--',
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onChanged: (_) => _calculateHealthMetrics(),
          ),
          const Text('L of 2.0L', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Colors.cyan),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(double width) {
    String suggestion;
    switch (_foodType) {
      case 'Junk':
        suggestion = '🍔 Reduce junk food intake. Try healthier alternatives!';
        break;
      case 'Healthy':
        suggestion = '🥗 Great choice! Keep eating healthy!';
        break;
      default:
        suggestion = '🥗 Balance your diet with more fruits and vegetables.';
    }

    return _buildGlassCard(
      glowColor: Colors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.restaurant, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Food Type', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('What did you eat today?', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.04),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: DropdownButton<String>(
              value: _foodType,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color(0xFF1a1a2e),
              style: const TextStyle(color: Colors.white),
              items: ['Junk', 'Healthy', 'Mixed'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) {
                setState(() => _foodType = value ?? 'Mixed');
                _calculateHealthMetrics();
              },
            ),
          ),
          SizedBox(height: width * 0.03),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF667eea), size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(suggestion, style: const TextStyle(color: Colors.white, fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressMoodSection(double width) {
    return _buildGlassCard(
      glowColor: _getStressColor(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStressColor().withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _stressLevel == 'High' ? Icons.sentiment_very_dissatisfied : _stressLevel == 'Medium' ? Icons.sentiment_neutral : Icons.sentiment_very_satisfied,
                  color: _getStressColor(),
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Stress Level', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(_stressLevel, style: TextStyle(color: _getStressColor(), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(width: 1, height: 80, color: Colors.white24),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(_stressEmoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 8),
              const Text('Mood', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                _healthScore >= 70 ? 'Happy' : _healthScore >= 50 ? 'Neutral' : 'Concerned',
                style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipsCard(double width) {
    return _buildGlassCard(
      glowColor: const Color(0xFF667eea),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tips_and_updates, color: Color(0xFF667eea), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Daily Health Tip', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: width * 0.04),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.2),
                  const Color(0xFF764ba2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF667eea), size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(_dailyTip, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(double width) {
    return ElevatedButton.icon(
      onPressed: () {
        _calculateHealthMetrics();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health data updated!'),
            backgroundColor: Color(0xFF667eea),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Update Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: width * 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
