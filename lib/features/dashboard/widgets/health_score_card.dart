import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';

class HealthScoreCard extends StatelessWidget {
  final double bmi;
  final double heartRisk;
  final double sleepHours;
  final int steps;
  
  const HealthScoreCard({
    required this.bmi,
    required this.heartRisk,
    required this.sleepHours,
    required this.steps,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double overallScore = calculateHealthScore();
    
    return GlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: height * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety, 
                  color: Colors.cyan, 
                  size: width * 0.06
                ),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    "Personal Health Dashboard",
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.02),
            
            // Overall Health Score with larger display
            _buildOverallScore(overallScore, width, height),
            SizedBox(height: height * 0.02),
            const Divider(color: Colors.white24, thickness: 1),
            SizedBox(height: height * 0.015),
            
            // Individual Scores
            _buildScoreRow("BMI Health", calculateBmiScore(), width, height),
            SizedBox(height: height * 0.01),
            
            _buildScoreRow("Heart Risk", 100 - heartRisk, width, height),
            SizedBox(height: height * 0.01),
            
            _buildScoreRow("Sleep Quality", calculateSleepScore(), width, height),
            SizedBox(height: height * 0.01),
            
            _buildScoreRow("Daily Activity", calculateActivityScore(), width, height),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverallScore(double score, double width, double height) {
    Color scoreColor = score >= 80 ? Colors.greenAccent : 
                      score >= 60 ? Colors.yellowAccent : Colors.redAccent;
    
    return Column(
      children: [
        Text(
          "Overall Health Score",
          style: TextStyle(
            color: Colors.white70,
            fontSize: width * 0.035,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: height * 0.01),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${score.toStringAsFixed(0)}",
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.08,
                letterSpacing: 2,
              ),
            ),
            Text(
              "%",
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.04,
              ),
            ),
            const Spacer(),
            Container(
              width: width * 0.3,
              height: height * 0.015,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.transparent,
                color: scoreColor,
                minHeight: height * 0.015,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildScoreRow(String label, double score, double width, double height) {
    Color scoreColor = score >= 80 ? Colors.greenAccent : 
                      score >= 60 ? Colors.yellowAccent : Colors.redAccent;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70, 
              fontSize: width * 0.03,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          "${score.toStringAsFixed(0)}%",
          style: TextStyle(
            color: scoreColor,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.035,
          ),
        ),
        SizedBox(width: width * 0.02),
        Container(
          width: width * 0.25,
          height: height * 0.012,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(6),
          ),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.transparent,
            color: scoreColor,
            minHeight: height * 0.012,
          ),
        ),
      ],
    );
  }
  
  double calculateHealthScore() {
    double bmiScore = calculateBmiScore();
    double sleepScore = calculateSleepScore();
    double activityScore = calculateActivityScore();
    double heartScore = 100 - heartRisk;
    
    return (bmiScore + sleepScore + activityScore + heartScore) / 4;
  }
  
  double calculateBmiScore() {
    if (bmi >= 18.5 && bmi <= 24.9) return 100; // Healthy BMI
    if (bmi >= 25 && bmi <= 29.9) return 70;    // Overweight
    if (bmi >= 30) return 40;                   // Obese
    return 60; // Underweight
  }
  
  double calculateSleepScore() {
    if (sleepHours >= 7 && sleepHours <= 9) return 100; // Ideal sleep
    if (sleepHours >= 6 && sleepHours < 7) return 80;
    if (sleepHours >= 5 && sleepHours < 6) return 60;
    if (sleepHours > 9) return 70; // Too much sleep
    return 40; // Too little sleep
  }
  
  double calculateActivityScore() {
    if (steps >= 10000) return 100; // Active
    if (steps >= 5000) return 70;   // Moderate
    if (steps >= 2500) return 40;   // Light
    return 20; // Sedentary
  }
}
