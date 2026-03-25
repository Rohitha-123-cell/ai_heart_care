import 'package:flutter/material.dart';
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final overallScore = calculateHealthScore();
    final metrics = [
      _ScoreItem("BMI Health", calculateBmiScore()),
      _ScoreItem("Heart Risk", 100 - heartRisk),
      _ScoreItem("Sleep Quality", calculateSleepScore()),
      _ScoreItem("Daily Activity", calculateActivityScore()),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.health_and_safety, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Personal Health Dashboard",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildOverallScore(overallScore),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics.map(_buildMetricChip).toList(),
          ),
          const SizedBox(height: 18),
          for (final metric in metrics) ...[
            _buildScoreRow(metric.label, metric.score),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallScore(double score) {
    final scoreColor = score >= 80
        ? Colors.greenAccent
        : score >= 60
            ? Colors.yellowAccent
            : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overall Health Score",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${score.toStringAsFixed(0)}",
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 52,
                letterSpacing: 1,
              ),
            ),
            Text(
              "%",
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const Spacer(),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.white12,
                  color: scoreColor,
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreRow(String label, double score) {
    final scoreColor = score >= 80
        ? Colors.greenAccent
        : score >= 60
            ? Colors.yellowAccent
            : Colors.redAccent;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "${score.toStringAsFixed(0)}%",
          style: TextStyle(
            color: scoreColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white12,
              color: scoreColor,
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(_ScoreItem metric) {
    final scoreColor = metric.score >= 80
        ? Colors.greenAccent
        : metric.score >= 60
            ? Colors.yellowAccent
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: scoreColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            metric.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  double calculateHealthScore() {
    final bmiScore = calculateBmiScore();
    final sleepScore = calculateSleepScore();
    final activityScore = calculateActivityScore();
    final heartScore = 100 - heartRisk;
    return (bmiScore + sleepScore + activityScore + heartScore) / 4;
  }

  double calculateBmiScore() {
    if (bmi >= 18.5 && bmi <= 24.9) return 100;
    if (bmi >= 25 && bmi <= 29.9) return 70;
    if (bmi >= 30) return 40;
    return 60;
  }

  double calculateSleepScore() {
    if (sleepHours >= 7 && sleepHours <= 9) return 100;
    if (sleepHours >= 6 && sleepHours < 7) return 80;
    if (sleepHours >= 5 && sleepHours < 6) return 60;
    if (sleepHours > 9) return 70;
    return 40;
  }

  double calculateActivityScore() {
    if (steps >= 10000) return 100;
    if (steps >= 5000) return 70;
    if (steps >= 2500) return 40;
    return 20;
  }
}

class _ScoreItem {
  final String label;
  final double score;

  const _ScoreItem(this.label, this.score);
}
