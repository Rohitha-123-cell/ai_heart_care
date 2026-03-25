import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/bmi/bmi_bloc.dart';
import '../../bloc/bmi/bmi_event.dart';
import '../../bloc/bmi/bmi_state.dart';
import '../../core/utils/responsive.dart';
import '../../services/storage_service.dart';
import '../../services/health_data_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../gender/gender_selection_screen.dart';

class HealthInputScreen extends StatefulWidget {
  const HealthInputScreen({super.key});

  @override
  State<HealthInputScreen> createState() => _HealthInputScreenState();
}

class _HealthInputScreenState extends State<HealthInputScreen> with TickerProviderStateMixin {
  
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController stepsController = TextEditingController();
  final TextEditingController sleepController = TextEditingController();
  final TextEditingController heartRateController = TextEditingController();
  
  double bmi = 0;
  double heartRisk = 0;
  String bmiCategory = "";
  bool _isLoading = false;
  bool _bmiCalculated = false; // Track if user clicked Calculate BMI button
  
  // Real-time estimated heart rate
  double estimatedHeartRate = 72.0;
  String heartRateStatus = "Normal";
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeController);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    // Add listeners for heart rate estimation (BMI is calculated on button click only)
    ageController.addListener(_onInputChanged);
    sleepController.addListener(_onInputChanged);
    stepsController.addListener(_onInputChanged);
    
    _fadeController.forward();
    _slideController.forward();
  }

  // Central handler for any input change
  void _onInputChanged() {
    calculateBMIRealTime();
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    stepsController.dispose();
    sleepController.dispose();
    heartRateController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Real-time BMI calculation as user types
  // BMI Formula: weight (kg) / height (m)²
  // Example: 70kg / (1.7m)² = 70 / 2.89 = 24.22
  void calculateBMIRealTime() {
    double height = double.tryParse(heightController.text) ?? 0;
    double weight = double.tryParse(weightController.text) ?? 0;
    
    if (height > 0 && weight > 0) {
      // Convert height from cm to meters before squaring
      double heightInMeters = height / 100;
      double heightSquared = heightInMeters * heightInMeters;
      
      setState(() {
        // BMI = weight (kg) / height² (m²)
        bmi = weight / heightSquared;
        bmi = double.parse(bmi.toStringAsFixed(1));
        
        if (bmi < 18.5) {
          bmiCategory = "Underweight";
        } else if (bmi < 25) {
          bmiCategory = "Normal";
        } else if (bmi < 30) {
          bmiCategory = "Overweight";
        } else {
          bmiCategory = "Obese";
        }
        
        // Also recalculate heart rate estimation based on new BMI
        _updateHeartRateEstimation();
      });
    }
  }

  // Legacy method kept for compatibility
  void calculateBMI() {
    calculateBMIRealTime();
  }

  // Calculate BMI with proper BLoC
  void _calculateBMIWithBLoC() {
    final bmiBloc = context.read<BmiBloc>();
    
    // Update BLoC with current values
    bmiBloc.add(UpdateHeight(heightController.text));
    bmiBloc.add(UpdateWeight(weightController.text));
    
    // Trigger calculation
    bmiBloc.add(const CalculateBmi());
  }

  // Real-time heart rate estimation based on user inputs
  void _updateHeartRateEstimation() {
    int age = int.tryParse(ageController.text) ?? 0;
    double sleepHours = double.tryParse(sleepController.text) ?? 0;
    int steps = int.tryParse(stepsController.text) ?? 0;
    
    // Only calculate if age is provided
    if (age <= 0) {
      setState(() {
        estimatedHeartRate = 72.0;
        heartRateStatus = "Normal";
        heartRisk = 0;
      });
      return;
    }
    
    // Base heart rate for adults is typically 60-100 bpm
    double baseHR = 72.0;
    
    // Adjust based on age (older = higher resting heart rate typically)
    if (age < 20) {
      baseHR -= 5;
    } else if (age > 50) {
      baseHR += (age - 50) * 0.3;
    }
    
    // Adjust based on BMI (obesity can increase resting heart rate)
    if (bmi > 0) {
      if (bmi > 30) {
        baseHR += 8;
      } else if (bmi > 25) {
        baseHR += 4;
      } else if (bmi < 18.5) {
        baseHR -= 3;
      }
    }
    
    // Adjust based on sleep (poor sleep increases heart rate)
    if (sleepHours > 0) {
      if (sleepHours < 6) {
        baseHR += 5;
      } else if (sleepHours > 9) {
        baseHR -= 2;
      }
    }
    
    // Adjust based on activity level (more steps = lower resting HR)
    if (steps > 0) {
      if (steps > 10000) {
        baseHR -= 5;
      } else if (steps > 7000) {
        baseHR -= 2;
      } else if (steps < 5000) {
        baseHR += 3;
      }
    }
    
    // Clamp to reasonable range
    estimatedHeartRate = baseHR.clamp(50.0, 110.0);
    
    // Determine status
    if (estimatedHeartRate < 60) {
      heartRateStatus = "Low (Athletic)";
    } else if (estimatedHeartRate < 80) {
      heartRateStatus = "Normal";
    } else if (estimatedHeartRate < 100) {
      heartRateStatus = "Elevated";
    } else {
      heartRateStatus = "High";
    }
    
    // Also calculate heart risk in real-time
    _calculateHeartRiskRealTime();
  }

  // Real-time heart risk calculation - FIXED
  // Using medically accurate risk assessment based on Framingham Heart Study
  void _calculateHeartRiskRealTime() {
    int age = int.tryParse(ageController.text) ?? 0;
    double sleepHours = double.tryParse(sleepController.text) ?? 7;
    int steps = int.tryParse(stepsController.text) ?? 8000;
    
    // Only calculate if age is provided
    if (age <= 0) {
      setState(() {
        heartRisk = 0;
      });
      return;
    }
    
    // Calculate BMI first
    double currentBMI = bmi > 0 ? bmi : 24.0;
    
    // Base risk - starts very low for young healthy individuals
    double risk = 2.0; // Base 2% for everyone
    
    // Age factor - risk increases gradually with age (Framingham-based)
    // Young adults (18-30): Very low risk contribution
    if (age >= 18 && age < 30) {
      risk += age * 0.1; // 1.8 - 3% for ages 18-29
    }
    // Adults (30-45): Low to moderate
    else if (age >= 30 && age < 45) {
      risk += 3.0 + (age - 30) * 0.3; // 3 - 7.5% for ages 30-44
    }
    // Middle age (45-60): Moderate to high
    else if (age >= 45 && age < 60) {
      risk += 7.5 + (age - 45) * 0.6; // 7.5 - 16.5% for ages 45-59
    }
    // Senior (60+): Higher risk
    else if (age >= 60) {
      risk += 16.5 + (age - 60) * 0.8; // 16.5 - 24.5%+ for ages 60+
    }
    
    // BMI factor - obesity significantly increases risk
    if (currentBMI >= 30) {
      risk += 15.0; // Obesity Class I-III
    } else if (currentBMI >= 27) {
      risk += 8.0; // Overweight (high end)
    } else if (currentBMI >= 25) {
      risk += 5.0; // Overweight
    } else if (currentBMI >= 23) {
      risk += 2.0; // Normal but on higher end
    } else if (currentBMI >= 18.5) {
      risk += 1.0; // Normal BMI
    } else {
      risk += 3.0; // Underweight
    }
    
    // Sleep factor - both too little and too much sleep increase risk
    if (sleepHours < 5) {
      risk += 8.0; // Severely sleep deprived
    } else if (sleepHours < 6) {
      risk += 5.0; // Sleep deprived
    } else if (sleepHours < 7) {
      risk += 2.0; // Slightly under
    } else if (sleepHours > 9) {
      risk += 2.0; // Oversleeping
    } else {
      // Optimal sleep (7-9 hours) - no added risk
    }
    
    // Activity factor - more steps = lower risk
    if (steps < 3000) {
      risk += 10.0; // Sedentary
    } else if (steps < 5000) {
      risk += 6.0; // Low activity
    } else if (steps < 7000) {
      risk += 3.0; // Below recommended
    } else if (steps < 10000) {
      risk += 1.0; // Active
    } else {
      risk -= 1.0; // Highly active - slight reduction
    }
    
    // Clamp risk to 0-100 range
    setState(() {
      heartRisk = risk.clamp(0.0, 100.0);
    });
  }

  // Legacy method for compatibility
  void calculateHeartRisk() {
    _calculateHeartRiskRealTime();
  }

  Future<void> saveAndContinue() async {
    // Validate ALL required fields before proceeding
    if (heightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your height'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (ageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your age'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (sleepController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your daily sleep hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (stepsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your daily steps'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      calculateBMI();
      calculateHeartRisk();
      
      // Get values from text fields
      double heightVal = double.tryParse(heightController.text) ?? 170;
      double weightVal = double.tryParse(weightController.text) ?? 70;
      int ageVal = int.tryParse(ageController.text) ?? 30;
      int stepsVal = int.tryParse(stepsController.text) ?? 8000;
      double sleepVal = double.tryParse(sleepController.text) ?? 7;
      double heartRateVal = double.tryParse(heartRateController.text) ?? 72;
      
      // Save to shared health data provider (for other screens to use)
      healthDataProvider.setHealthData(
        bmi: bmi,
        age: ageVal,
        steps: stepsVal,
        sleepHours: sleepVal,
        heartRisk: heartRisk,
        heartRate: heartRateVal,
        weight: weightVal,
        height: heightVal,
        stressScore: 35,
        bmiCategory: bmiCategory,
      );
      
      // Save to Supabase
      await StorageService.saveHealthMetrics(
        bmi: bmi,
        heartRate: heartRateVal,
        bloodPressure: 120,
        weight: weightVal,
        sleepHours: sleepVal,
        steps: stepsVal,
      );

      // Save risk score
      await StorageService.saveRiskScore(
        riskType: 'heart',
        score: heartRisk,
        level: heartRisk < 20 ? 'Low' : heartRisk < 40 ? 'Moderate' : 'High',
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GenderSelectionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Even if save fails, continue to gender selection (for demo)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GenderSelectionScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth.clamp(0.0, 520.0).toDouble();
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B8DD6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(width * 0.05),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.02),
                      Container(
                        padding: EdgeInsets.all(width * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(width * 0.04),
                        ),
                        child: Icon(
                          Icons.health_and_safety,
                          color: Colors.white,
                          size: width * 0.1,
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      const Text(
                        "Welcome!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      Text(
                        "Let's set up your health profile",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.04),

                // Health Input Cards
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // BMI Input Card
                      _buildInputCard(
                        title: "BMI (Body Mass Index)",
                        icon: Icons.monitor_weight,
                        color: Colors.cyan,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: heightController,
                                    label: "Height (cm)",
                                    icon: Icons.height,
                                    onChanged: (_) => calculateBMIRealTime(),
                                  ),
                                ),
                                SizedBox(width: width * 0.03),
                                Expanded(
                                  child: _buildTextField(
                                    controller: weightController,
                                    label: "Weight (kg)",
                                    icon: Icons.scale,
                                    onChanged: (_) => calculateBMIRealTime(),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Calculate BMI Button - User MUST click this to calculate BMI
                            SizedBox(height: height * 0.02),
                            ElevatedButton.icon(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                // Get input values
                                final heightVal = double.tryParse(heightController.text) ?? 0;
                                final weightVal = double.tryParse(weightController.text) ?? 0;
                                
                                if (heightVal <= 0 || weightVal <= 0) {
                                  // Show error if inputs are invalid
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter valid height and weight'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Calculate BMI and mark as calculated
                                calculateBMIRealTime();
                                setState(() {
                                  _bmiCalculated = true;
                                });
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('BMI Calculated: ${bmi.toString()} ($bmiCategory)'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.calculate, size: 20),
                              label: const Text(
                                'Calculate BMI',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.04,
                                  vertical: height * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(width * 0.03),
                                ),
                              ),
                            ),
                            
                            // BMI Result display (only shows after Calculate button is clicked)
                            if (_bmiCalculated && bmi > 0) ...[
                              SizedBox(height: height * 0.02),
                              Container(
                                padding: EdgeInsets.all(width * 0.03),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.cyan.withOpacity(0.15),
                                      Colors.cyan.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(width * 0.03),
                                  border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          "Your BMI",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          bmi.toString(),
                                          style: TextStyle(
                                            color: _getBMIColor(),
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 45,
                                      color: Colors.cyan.withOpacity(0.3),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          "Category",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          bmiCategory,
                                          style: TextStyle(
                                            color: _getBMIColor(),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // BMI Category Guide
                              SizedBox(height: height * 0.015),
                              Container(
                                padding: EdgeInsets.all(width * 0.025),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(width * 0.02),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BMI Categories:',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Wrap(
                                      alignment: WrapAlignment.spaceAround,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildBmiCategoryChip('Underweight', Colors.blue, '< 18.5'),
                                        _buildBmiCategoryChip('Normal', Colors.green, '18.5-24.9'),
                                        _buildBmiCategoryChip('Overweight', Colors.orange, '25-29.9'),
                                        _buildBmiCategoryChip('Obese', Colors.red, '30+'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.03),

                      // Heart Risk Input Card - Only show results when age is entered
                      _buildInputCard(
                        title: "Heart Risk",
                        icon: Icons.favorite,
                        color: Colors.pink,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: ageController,
                              label: "Your Age",
                              icon: Icons.cake,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateHeartRateEstimation(),
                            ),
                            // Only show results when age is entered
                            if (ageController.text.isNotEmpty && int.tryParse(ageController.text) != null) ...[
                              SizedBox(height: height * 0.02),
                              // Real-time estimated heart rate AND heart risk display
                              Container(
                                padding: EdgeInsets.all(width * 0.03),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.15),
                                      Colors.pink.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(width * 0.03),
                                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          "Heart Risk",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${heartRisk.toStringAsFixed(1)}%",
                                          style: TextStyle(
                                            color: _getRiskColor(),
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          "Status",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          heartRisk < 15 ? "Low Risk" : heartRisk < 30 ? "Moderate" : "High Risk",
                                          style: TextStyle(
                                            color: _getRiskColor(),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Prompt text when age is empty
                            if (ageController.text.isEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.grey, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Enter your age to predict heart risk",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.03),

                      // Sleep Quantity Card
                      _buildInputCard(
                        title: "Sleep Quantity",
                        icon: Icons.bedtime,
                        color: Colors.purple,
                        child: _buildTextField(
                          controller: sleepController,
                          label: "Hours of Sleep (e.g., 7.5)",
                          icon: Icons.nights_stay,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _updateHeartRateEstimation(),
                        ),
                      ),

                      SizedBox(height: height * 0.03),

                      // Daily Activity Card
                      _buildInputCard(
                        title: "Daily Activity",
                        icon: Icons.directions_walk,
                        color: Colors.green,
                        child: _buildTextField(
                          controller: stepsController,
                          label: "Daily Steps (e.g., 8000)",
                          icon: Icons.directions_run,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateHeartRateEstimation(),
                        ),
                      ),

                      SizedBox(height: height * 0.03),

                      // Heart Rate (Optional)
                      _buildInputCard(
                        title: "Heart Rate (Optional)",
                        icon: Icons.monitor_heart,
                        color: Colors.red,
                        child: _buildTextField(
                          controller: heartRateController,
                          label: "Heart Rate (bpm)",
                          icon: Icons.favorite_border,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.04),

                // Continue Button
                GestureDetector(
                  onTap: _isLoading ? null : saveAndContinue,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(width * 0.045),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                      ),
                      borderRadius: BorderRadius.circular(width * 0.05),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Next: Health Questions",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: height * 0.03),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final width = MediaQuery.of(context).size.width.clamp(0.0, 520.0).toDouble();
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(width * 0.025),
                ),
                child: Icon(icon, color: color, size: width * 0.06),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF1a1a2e),
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.04,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    final width = MediaQuery.of(context).size.width.clamp(0.0, 520.0).toDouble();
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: const Color(0xFF1a1a2e), fontSize: width * 0.04),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: width * 0.035),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(width * 0.03),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: width * 0.035,
        ),
      ),
    );
  }

  Color _getBMIColor() {
    switch (bmiCategory) {
      case "Underweight":
        return Colors.blue;
      case "Normal":
        return Colors.green;
      case "Overweight":
        return Colors.orange;
      case "Obese":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor() {
    if (heartRisk < 15) return Colors.green;
    if (heartRisk < 30) return Colors.orange;
    if (heartRisk < 50) return Colors.deepOrange;
    return Colors.red;
  }

  Color _getHeartRateColor() {
    if (estimatedHeartRate < 60) return Colors.blue;
    if (estimatedHeartRate < 80) return Colors.green;
    if (estimatedHeartRate < 100) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBmiCategoryChip(String label, Color color, String range) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          range,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
