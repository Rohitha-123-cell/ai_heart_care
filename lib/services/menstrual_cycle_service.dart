class CycleRecord {
  final DateTime startDate;
  final DateTime endDate;
  final double averageTemperature;
  final String healthCondition;
  final String flowIntensity;

  const CycleRecord({
    required this.startDate,
    required this.endDate,
    required this.averageTemperature,
    required this.healthCondition,
    required this.flowIntensity,
  });

  int get periodLength => endDate.difference(startDate).inDays + 1;
}

class SymptomEntry {
  final DateTime date;
  final List<String> symptoms;
  final String flowIntensity;
  final double bodyTemperature;
  final String bodyChanges;
  final String notes;

  const SymptomEntry({
    required this.date,
    required this.symptoms,
    required this.flowIntensity,
    required this.bodyTemperature,
    required this.bodyChanges,
    required this.notes,
  });
}

class ReminderItem {
  final String title;
  final String detail;
  final DateTime scheduledFor;

  const ReminderItem({
    required this.title,
    required this.detail,
    required this.scheduledFor,
  });
}

class CyclePrediction {
  final List<int> cycleLengths;
  final int averageCycleLength;
  final int averagePeriodLength;
  final DateTime nextPeriodStart;
  final DateTime nextPeriodEnd;
  final DateTime ovulationDay;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final DateTime pmsAlertDate;
  final bool irregularCycleDetected;
  final List<String> insights;
  final List<ReminderItem> reminders;

  const CyclePrediction({
    required this.cycleLengths,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.nextPeriodStart,
    required this.nextPeriodEnd,
    required this.ovulationDay,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.pmsAlertDate,
    required this.irregularCycleDetected,
    required this.insights,
    required this.reminders,
  });
}

class MenstrualCycleService {
  static const List<String> commonSymptoms = [
    'Cramps',
    'Mood swings',
    'Fatigue',
    'Bloating',
    'Headache',
    'Back pain',
    'Acne',
    'Food cravings',
  ];

  static CyclePrediction generatePrediction({
    required List<CycleRecord> records,
    required List<SymptomEntry> symptoms,
    required bool periodReminderEnabled,
    required bool ovulationReminderEnabled,
    required bool medicationReminderEnabled,
    required bool pregnancyModeEnabled,
    required bool birthControlEnabled,
  }) {
    final sortedRecords = [...records]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final cycleLengths = <int>[];

    for (var i = 1; i < sortedRecords.length; i++) {
      cycleLengths.add(
        sortedRecords[i].startDate
            .difference(sortedRecords[i - 1].startDate)
            .inDays,
      );
    }

    final averageCycleLength = cycleLengths.isEmpty
        ? 28
        : (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length).round();
    final averagePeriodLength = sortedRecords.isEmpty
        ? 5
        : (sortedRecords
                      .map((record) => record.periodLength)
                      .reduce((a, b) => a + b) /
                  sortedRecords.length)
              .round();

    final latestRecord = sortedRecords.isNotEmpty
        ? sortedRecords.last
        : CycleRecord(
            startDate: DateTime.now().subtract(const Duration(days: 28)),
            endDate: DateTime.now().subtract(const Duration(days: 24)),
            averageTemperature: 36.7,
            healthCondition: 'Stable',
            flowIntensity: 'Moderate',
          );

    final nextPeriodStart = latestRecord.startDate.add(
      Duration(days: averageCycleLength),
    );
    final nextPeriodEnd = nextPeriodStart.add(
      Duration(days: averagePeriodLength - 1),
    );
    final ovulationDay = nextPeriodStart.subtract(const Duration(days: 14));
    final fertileWindowStart = ovulationDay.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDay.add(const Duration(days: 1));
    final pmsAlertDate = nextPeriodStart.subtract(const Duration(days: 5));

    final irregularCycleDetected = _isIrregular(cycleLengths);
    final insights = _buildInsights(
      records: sortedRecords,
      symptoms: symptoms,
      irregularCycleDetected: irregularCycleDetected,
      pregnancyModeEnabled: pregnancyModeEnabled,
      birthControlEnabled: birthControlEnabled,
    );

    final reminders = <ReminderItem>[
      if (periodReminderEnabled)
        ReminderItem(
          title: 'Upcoming period',
          detail: 'Prepare for your next cycle and log symptoms early.',
          scheduledFor: nextPeriodStart.subtract(const Duration(days: 2)),
        ),
      if (ovulationReminderEnabled)
        ReminderItem(
          title: 'Ovulation window',
          detail: 'Fertile window expected around this date.',
          scheduledFor: fertileWindowStart,
        ),
      ReminderItem(
        title: 'PMS alert',
        detail: 'Watch for mood, cramps, and fatigue changes.',
        scheduledFor: pmsAlertDate,
      ),
      if (medicationReminderEnabled)
        ReminderItem(
          title: 'Medication tracking',
          detail: 'Take and confirm your prescribed medicine or supplements.',
          scheduledFor: DateTime.now().add(const Duration(hours: 8)),
        ),
    ]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));

    return CyclePrediction(
      cycleLengths: cycleLengths,
      averageCycleLength: averageCycleLength,
      averagePeriodLength: averagePeriodLength,
      nextPeriodStart: nextPeriodStart,
      nextPeriodEnd: nextPeriodEnd,
      ovulationDay: ovulationDay,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      pmsAlertDate: pmsAlertDate,
      irregularCycleDetected: irregularCycleDetected,
      insights: insights,
      reminders: reminders,
    );
  }

  static bool _isIrregular(List<int> cycleLengths) {
    if (cycleLengths.length < 2) return false;
    final shortest = cycleLengths.reduce((a, b) => a < b ? a : b);
    final longest = cycleLengths.reduce((a, b) => a > b ? a : b);
    return shortest < 21 || longest > 35 || (longest - shortest) > 7;
  }

  static List<String> _buildInsights({
    required List<CycleRecord> records,
    required List<SymptomEntry> symptoms,
    required bool irregularCycleDetected,
    required bool pregnancyModeEnabled,
    required bool birthControlEnabled,
  }) {
    final insights = <String>[];

    if (records.isNotEmpty) {
      final latest = records.last;
      if (latest.averageTemperature >= 37.2) {
        insights.add(
          'Elevated temperature trend detected. Track for ovulation confirmation or illness.',
        );
      }
      if (latest.periodLength > 7) {
        insights.add(
          'Recent bleeding length is above 7 days. Consider discussing this with a doctor.',
        );
      }
    }

    final crampsCount = symptoms
        .where((entry) => entry.symptoms.contains('Cramps'))
        .length;
    final moodCount = symptoms
        .where((entry) => entry.symptoms.contains('Mood swings'))
        .length;
    final fatigueCount = symptoms
        .where((entry) => entry.symptoms.contains('Fatigue'))
        .length;

    if (crampsCount >= 3) {
      insights.add(
        'Frequent cramps logged. Hydration, heat support, and medical review may help.',
      );
    }
    if (moodCount >= 3) {
      insights.add(
        'Mood changes are recurring. PMS support and stress tracking may improve comfort.',
      );
    }
    if (fatigueCount >= 3) {
      insights.add(
        'Repeated fatigue pattern found. Prioritize iron-rich meals, sleep, and recovery.',
      );
    }
    if (irregularCycleDetected) {
      insights.add(
        'Cycle variability looks irregular. Keep logging and consider professional review if this continues.',
      );
    } else {
      insights.add(
        'Your recent cycle pattern looks reasonably consistent, which improves prediction quality.',
      );
    }
    if (pregnancyModeEnabled) {
      insights.add(
        'Pregnancy mode is enabled. Focus more on symptom stability, temperature changes, and missed periods.',
      );
    }
    if (birthControlEnabled) {
      insights.add(
        'Birth control tracking is enabled. Log pills, injections, or device dates to improve adherence.',
      );
    }
    if (insights.isEmpty) {
      insights.add(
        'Add more cycle and symptom entries to unlock more personalized insights.',
      );
    }

    return insights;
  }
}
