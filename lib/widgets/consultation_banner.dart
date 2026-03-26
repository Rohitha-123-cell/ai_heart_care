import 'package:flutter/material.dart';

class ConsultationBanner extends StatelessWidget {
  final bool show;

  const ConsultationBanner({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Consider consulting a doctor based on your cycle patterns.",
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}