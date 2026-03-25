import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/step_counter_service.dart';
import '../../core/utils/responsive.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen>
    with SingleTickerProviderStateMixin {
  final StepCounterService _stepService = StepCounterService();

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  bool _isTracking = false;
  int _currentSteps = 0;
  int _dailyGoal = 10000;
  StreamSubscription? _stepsSubscription;
  
  // For demo/testing when no sensor available
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Initialize service
    _stepService.initialize();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _stopTracking();
    super.dispose();
  }

  void _startTracking() async {
    await _stepService.initialize();
    
    setState(() {
      _isTracking = true;
    });

    _stepService.setDailyGoal(_dailyGoal);
    
    // Try to use the step counter service
    _stepsSubscription = _stepService.startCounting().listen(
      (steps) {
        if (steps > 0) {
          setState(() {
            _currentSteps = steps;
            double progress = (_currentSteps / _dailyGoal).clamp(0.0, 1.0);
            _progressController.animateTo(progress);
          });
        }
      },
      onError: (error) {
        // If real step counter fails, use demo mode
        _startDemoMode();
      },
    );

    // Start demo mode after a short delay if no steps detected
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isTracking && _currentSteps == 0) {
        _startDemoMode();
      }
    });
  }

  void _startDemoMode() {
    if (!mounted || !_isTracking) return;
    
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // Simulate random steps
        int newSteps = 5 + (DateTime.now().second % 15);
        _currentSteps += newSteps;
        
        if (_currentSteps >= _dailyGoal) {
          _currentSteps = _dailyGoal;
          timer.cancel();
        }
        
        double progress = (_currentSteps / _dailyGoal).clamp(0.0, 1.0);
        _progressController.animateTo(progress);
      });
    });
  }

  void _stopTracking() {
    _stepService.stopCounting();
    _stepsSubscription?.cancel();
    _demoTimer?.cancel();
    
    setState(() {
      _isTracking = false;
    });
  }

  void _setGoal(int goal) {
    setState(() {
      _dailyGoal = goal;
      _stepService.setDailyGoal(goal);
    });
  }

  double get _progress => (_currentSteps / _dailyGoal).clamp(0.0, 1.0);
  int get _stepsRemaining => (_dailyGoal - _currentSteps).clamp(0, _dailyGoal);
  double get _distanceKm => _currentSteps * 0.0007;
  double get _caloriesBurned => _currentSteps * 0.04;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth.clamp(0.0, 520.0).toDouble();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0f2027),
              const Color(0xFF203a43),
              const Color(0xFF2c5364),
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
                      // Progress Ring Card
                      _buildProgressCard(width),
                      SizedBox(height: width * 0.04),

                      // Stats Grid
                      _buildStatsGrid(width),
                      SizedBox(height: width * 0.04),

                      // Motivational Message
                      _buildMotivationalCard(width),
                      SizedBox(height: width * 0.04),

                      // Goal Selector
                      _buildGoalSelector(width),
                      SizedBox(height: width * 0.04),

                      // Action Button
                      _buildActionButton(width),
                      SizedBox(height: width * 0.04),

                      // Hourly Progress
                      _buildHourlyProgress(width),
                      SizedBox(height: width * 0.04),
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
                  'Step Counter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track your daily activity',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.03,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isTracking 
                  ? Colors.green.withOpacity(0.3) 
                  : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isTracking ? Colors.green : Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isTracking ? Icons.directions_walk : Icons.pause,
                  color: _isTracking ? Colors.green : Colors.grey,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  _isTracking ? "Active" : "Stopped",
                  style: TextStyle(
                    color: _isTracking ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double width) {
    Color progressColor = _progress >= 1.0 ? Colors.amber : const Color(0xFF38ef7d);
    
    return Container(
      padding: EdgeInsets.all(width * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withOpacity(0.15),
            progressColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: progressColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Circular Progress
          SizedBox(
            width: width * 0.5,
            height: width * 0.5,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Circle
                    SizedBox(
                      width: width * 0.45,
                      height: width * 0.45,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 18,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    // Progress Circle
                    SizedBox(
                      width: width * 0.45,
                      height: width * 0.45,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 18,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(progressColor),
                      ),
                    ),
                    // Center Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(width * 0.03),
                          decoration: BoxDecoration(
                            color: progressColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _progress >= 1.0 ? Icons.emoji_events : Icons.directions_walk,
                            color: progressColor,
                            size: width * 0.08,
                          ),
                        ),
                        SizedBox(height: width * 0.02),
                        Text(
                          "${(_progress * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.08,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "of goal",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: width * 0.03,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          SizedBox(height: width * 0.04),

          // Step Count - Large and Clear
          Container(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: width * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_walk, color: const Color(0xFF38ef7d), size: 28),
                SizedBox(width: 8),
                Text(
                  "$_currentSteps",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "/ $_dailyGoal",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: width * 0.06,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: width * 0.02),
          Text(
            "steps today",
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.035,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: width * 0.03),

          // Remaining Steps
          Container(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: width * 0.02),
            decoration: BoxDecoration(
              color: progressColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: progressColor.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _stepsRemaining > 0 ? Icons.flag : Icons.check_circle,
                  color: progressColor,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  _stepsRemaining > 0 
                      ? "$_stepsRemaining steps to go" 
                      : "Goal Achieved! 🎉",
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.035,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double width) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            width,
            "Distance",
            "${_distanceKm.toStringAsFixed(2)} km",
            Icons.straighten,
            Colors.cyan,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildStatCard(
            width,
            "Calories",
            "${_caloriesBurned.toStringAsFixed(0)} cal",
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildStatCard(
            width,
            "Goal",
            "${(_dailyGoal / 1000).toStringAsFixed(0)}k",
            Icons.flag,
            Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    double width,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: width * 0.07),
          SizedBox(height: width * 0.01),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: width * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.028,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.tips_and_updates, color: Colors.amber, size: width * 0.07),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daily Motivation",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.035,
                  ),
                ),
                SizedBox(height: width * 0.01),
                Text(
                  _stepService.getMotivationalMessage(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.032,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelector(double width) {
    final List<int> goals = [5000, 8000, 10000, 15000];
    
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                "Daily Goal",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: goals.map((goal) {
              bool isSelected = _dailyGoal == goal;
              return GestureDetector(
                onTap: () => _setGoal(goal),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: width * 0.025,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF38ef7d).withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF38ef7d) 
                          : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    "${(goal / 1000).toStringAsFixed(goal == 15000 ? 1 : 0)}k",
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF38ef7d) 
                          : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: width * 0.038,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(double width) {
    return GestureDetector(
      onTap: _isTracking ? _stopTracking : _startTracking,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.045),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isTracking
                ? [Colors.red.withOpacity(0.8), Colors.red]
                : [const Color(0xFF38ef7d), const Color(0xFF11998e)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_isTracking ? Colors.red : const Color(0xFF38ef7d))
                  .withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTracking ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
              size: width * 0.06,
            ),
            SizedBox(width: width * 0.02),
            Text(
              _isTracking ? "Stop Tracking" : "Start Tracking",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.045,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyProgress(double width) {
    List<int> hourlySteps = _stepService.getHourlySteps();
    int currentHour = DateTime.now().hour;
    int maxSteps = hourlySteps.reduce((a, b) => a > b ? a : b);
    if (maxSteps == 0) maxSteps = 100;

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                "Hourly Progress",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (index) {
                  int hour = (currentHour - 11 + index) % 24;
                  int steps = hour < hourlySteps.length ? hourlySteps[hour] : 0;
                  double heightRatio = steps / maxSteps;
                  bool isCurrent = hour == currentHour;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.01),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Step count above bar
                        if (steps > 0)
                          Text(
                            "${(steps / 100).toStringAsFixed(1)}k",
                            style: TextStyle(
                              color: isCurrent 
                                  ? const Color(0xFF38ef7d) 
                                  : Colors.white70,
                              fontSize: width * 0.028,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          SizedBox(height: 16),
                        SizedBox(height: 4),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: width * 0.06,
                          height: (80 * heightRatio).clamp(8.0, 80.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isCurrent
                                  ? [const Color(0xFF38ef7d), Colors.lightGreen]
                                  : [const Color(0xFF38ef7d).withOpacity(0.5), const Color(0xFF38ef7d).withOpacity(0.2)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isCurrent
                                ? [BoxShadow(color: const Color(0xFF38ef7d).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 2))]
                                : [],
                          ),
                        ),
                        SizedBox(height: 6),
                        // Hour label
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCurrent 
                                ? const Color(0xFF38ef7d).withOpacity(0.3) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${hour.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: isCurrent 
                                  ? Colors.white 
                                  : Colors.white54,
                              fontSize: width * 0.03,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
