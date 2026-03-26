import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportGeneratorService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Generate comprehensive health report
  Future<Map<String, dynamic>> generateHealthReport({
    required String userId,
    required String userName,
    required double bmi,
    required int dailySteps,
    required double sleepHours,
    required double heartRisk,
    required int stressScore,
    double? bloodPressure,
    double? cholesterol,
    int? heartRate,
  }) async {
    // Gather all health data
    Map<String, dynamic> reportData = {
      'user_name': userName,
      'date': DateTime.now().toIso8601String(),
      'summary': _generateSummary(bmi, dailySteps, sleepHours, heartRisk, stressScore),
      'vitals': {
        'bmi': bmi,
        'bmi_category': _getBMICategory(bmi),
        'daily_steps': dailySteps,
        'sleep_hours': sleepHours,
        'heart_risk': heartRisk,
        'stress_score': stressScore,
        'blood_pressure': bloodPressure ?? 'Not recorded',
        'cholesterol': cholesterol ?? 'Not recorded',
        'heart_rate': heartRate ?? 'Not recorded',
      },
      'recommendations': _generateRecommendations(bmi, dailySteps, sleepHours, heartRisk, stressScore),
      'risk_assessment': _assessRisks(bmi, dailySteps, heartRisk, stressScore),
    };

    // Save report metadata
    await _saveReportMetadata(userId, reportData);

    return reportData;
  }

  String _generateSummary(double bmi, int steps, double sleep, double heartRisk, int stress) {
    List<String> highlights = [];
    
    if (bmi >= 18.5 && bmi < 25) highlights.add("Healthy weight");
    if (steps >= 8000) highlights.add("Active lifestyle");
    if (sleep >= 7 && sleep <= 9) highlights.add("Good sleep");
    if (heartRisk < 30) highlights.add("Low heart risk");
    if (stress < 40) highlights.add("Manageable stress");
    
    if (highlights.isEmpty) {
      return "Your health profile shows several areas that could benefit from improvement. Focus on the recommendations below.";
    }
    
    return "Health highlights: ${highlights.join(', ')}. See detailed analysis below.";
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  List<String> _generateRecommendations(double bmi, int steps, double sleep, double heartRisk, int stress) {
    List<String> recs = [];

    if (bmi < 18.5) {
      recs.add("Increase caloric intake with nutrient-dense foods");
      recs.add("Consider consulting a nutritionist");
    } else if (bmi > 25) {
      recs.add("Aim for 150 minutes of moderate exercise weekly");
      recs.add("Reduce processed food and sugar intake");
    }

    if (steps < 8000) {
      recs.add("Gradually increase daily steps by 500 each week");
      recs.add("Take short walks during breaks");
    }

    if (sleep < 7) {
      recs.add("Establish a consistent sleep schedule");
      recs.add("Limit screen time before bed");
    }

    if (heartRisk > 40) {
      recs.add("Schedule cardiovascular screening");
      recs.add("Monitor blood pressure regularly");
    }

    if (stress > 50) {
      recs.add("Practice daily mindfulness or meditation");
      recs.add("Consider speaking with a mental health professional");
    }

    return recs;
  }

  List<Map<String, String>> _assessRisks(double bmi, int steps, double heartRisk, int stress) {
    List<Map<String, String>> risks = [];

    if (bmi > 30) {
      risks.add({
        'condition': 'Obesity',
        'risk_level': 'High',
        'timeframe': 'Long-term',
        'prevention': 'Diet and exercise modifications',
      });
    } else if (bmi > 25) {
      risks.add({
        'condition': 'Overweight',
        'risk_level': 'Moderate',
        'timeframe': 'Gradual',
        'prevention': 'Lifestyle changes',
      });
    }

    if (heartRisk > 50) {
      risks.add({
        'condition': 'Cardiovascular Disease',
        'risk_level': 'High',
        'timeframe': '1-5 years',
        'prevention': 'Cardiac screening and lifestyle changes',
      });
    }

    if (stress > 60) {
      risks.add({
        'condition': 'Chronic Stress',
        'risk_level': 'Moderate',
        'timeframe': 'Ongoing',
        'prevention': 'Stress management techniques',
      });
    }

    if (steps < 5000) {
      risks.add({
        'condition': 'Sedentary Lifestyle',
        'risk_level': 'Moderate',
        'timeframe': 'Gradual',
        'prevention': 'Regular physical activity',
      });
    }

    return risks;
  }

  Future<void> _saveReportMetadata(String userId, Map<String, dynamic> reportData) async {
    try {
      await _client.from('health_reports').insert({
        'user_id': userId,
        'report_date': reportData['date'],
        'summary': reportData['summary'],
        'bmi': reportData['vitals']['bmi'],
        'steps': reportData['vitals']['daily_steps'],
        'heart_risk': reportData['vitals']['heart_risk'],
      });
    } catch (e) {
      print('Error saving report metadata: $e');
    }
  }

  /// Generate text-based report (simple version without PDF library)
  Future<String> generateTextReport({
    required String userName,
    required double bmi,
    required int dailySteps,
    required double sleepHours,
    required double heartRisk,
    required int stressScore,
  }) async {
    StringBuffer report = StringBuffer();
    
    report.writeln("=" * 50);
    report.writeln("       AI HEALTH GUARDIAN - HEALTH REPORT");
    report.writeln("=" * 50);
    report.writeln();
    report.writeln("Patient: $userName");
    report.writeln("Date: ${DateTime.now().toString().split(' ')[0]}");
    report.writeln();
    report.writeln("-" * 50);
    report.writeln("                    VITAL SIGNS");
    report.writeln("-" * 50);
    report.writeln();
    report.writeln("BMI:              ${bmi.toStringAsFixed(1)} (${_getBMICategory(bmi)})");
    report.writeln("Daily Steps:      $dailySteps");
    report.writeln("Sleep Hours:      ${sleepHours.toStringAsFixed(1)} hrs");
    report.writeln("Heart Risk:       ${heartRisk.toStringAsFixed(0)}%");
    report.writeln("Stress Score:     $stressScore%");
    report.writeln();
    report.writeln("-" * 50);
    report.writeln("              RECOMMENDATIONS");
    report.writeln("-" * 50);
    report.writeln();
    
    List<String> recs = _generateRecommendations(bmi, dailySteps, sleepHours, heartRisk, stressScore);
    for (int i = 0; i < recs.length; i++) {
      report.writeln("${i + 1}. ${recs[i]}");
    }
    
    report.writeln();
    report.writeln("-" * 50);
    report.writeln("                DISCLAIMER");
    report.writeln("-" * 50);
    report.writeln();
    report.writeln("This report is generated by AI and is for");
    report.writeln("informational purposes only. It should not");
    report.writeln("be considered medical advice. Please");
    report.writeln("consult a qualified healthcare professional");
    report.writeln("for diagnosis and treatment.");
    report.writeln();
    report.writeln("=" * 50);
    
    return report.toString();
  }

  /// Save and share report
  Future<Map<String, String>> saveAndShareReport({
    required String reportContent,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        // Web: use text-only sharing (Web Share API supports text on all browsers)
        await Share.share(
          reportContent,
          subject: 'Health Report - AI Health Guardian',
        );
      } else {
        // Mobile: share as a file attachment
        final Uint8List bytes = Uint8List.fromList(utf8.encode(reportContent));
        final XFile xFile = XFile.fromData(
          bytes,
          name: '$fileName.txt',
          mimeType: 'text/plain',
        );
        await Share.shareXFiles(
          [xFile],
          text: 'My Health Report from AI Health Guardian',
        );
      }
      return {'path': fileName, 'status': 'success'};
    } catch (e) {
      return {'path': '', 'status': 'error: ${e.toString()}'};
    }
  }

  /// Get report history
  Future<List<Map<String, dynamic>>> getReportHistory(String userId) async {
    try {
      final response = await _client
          .from('health_reports')
          .select()
          .eq('user_id', userId)
          .order('report_date', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching report history: $e');
      return [];
    }
  }
}
