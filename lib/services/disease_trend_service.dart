class DiseaseTrendRecord {
  final DateTime date;
  final String region;
  final String disease;
  final int cases;

  const DiseaseTrendRecord({
    required this.date,
    required this.region,
    required this.disease,
    required this.cases,
  });
}

class TrendSummary {
  final List<DiseaseTrendRecord> records;
  final int latestCases;
  final int peakCases;
  final double averageCases;
  final List<DiseaseTrendRecord> abnormalPoints;

  const TrendSummary({
    required this.records,
    required this.latestCases,
    required this.peakCases,
    required this.averageCases,
    required this.abnormalPoints,
  });
}

class DiseaseTrendService {
  static const List<String> diseases = ['Dengue', 'Flu', 'Covid-19'];
  static const List<String> regions = ['All Regions', 'North Zone', 'Central Zone', 'South Zone'];

  List<DiseaseTrendRecord> loadLocalDataset() {
    final startDate = DateTime(2026, 3, 1);
    final data = <DiseaseTrendRecord>[];
    const regionFactors = {
      'North Zone': 1.0,
      'Central Zone': 1.2,
      'South Zone': 0.85,
    };
    const diseaseFactors = {
      'Dengue': 18,
      'Flu': 30,
      'Covid-19': 22,
    };

    for (var day = 0; day < 30; day++) {
      final date = startDate.add(Duration(days: day));
      for (final disease in diseases) {
        for (final region in regionFactors.keys) {
          final base = diseaseFactors[disease]!;
          final seasonalWave = ((day % 7) * 2) + ((day ~/ 6) * 3);
          final peakBoost = (day == 11 || day == 18 || day == 24) ? 12 : 0;
          final regionAdjustment = (base * regionFactors[region]!).round();
          final diseaseAdjustment = disease == 'Flu'
              ? (day > 15 ? 10 : 0)
              : disease == 'Dengue'
                  ? (day > 20 ? 8 : 0)
                  : (day >= 8 && day <= 16 ? 6 : 0);

          data.add(
            DiseaseTrendRecord(
              date: date,
              region: region,
              disease: disease,
              cases: regionAdjustment + seasonalWave + peakBoost + diseaseAdjustment,
            ),
          );
        }
      }
    }

    return data;
  }

  TrendSummary buildSummary({
    required List<DiseaseTrendRecord> dataset,
    required String disease,
    required String region,
    required int days,
  }) {
    final filtered = dataset.where((record) {
      final diseaseMatch = record.disease == disease;
      final regionMatch = region == 'All Regions' || record.region == region;
      return diseaseMatch && regionMatch;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final cutoff = filtered.isNotEmpty
        ? filtered.last.date.subtract(Duration(days: days - 1))
        : DateTime.now();

    final recent = filtered.where((record) => !record.date.isBefore(cutoff)).toList();
    final grouped = <DateTime, int>{};

    for (final record in recent) {
      final key = DateTime(record.date.year, record.date.month, record.date.day);
      grouped[key] = (grouped[key] ?? 0) + record.cases;
    }

    final records = grouped.entries
        .map(
          (entry) => DiseaseTrendRecord(
            date: entry.key,
            region: region,
            disease: disease,
            cases: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (records.isEmpty) {
      return const TrendSummary(
        records: [],
        latestCases: 0,
        peakCases: 0,
        averageCases: 0,
        abnormalPoints: [],
      );
    }

    final total = records.fold<int>(0, (sum, item) => sum + item.cases);
    final average = total / records.length;
    final peak = records.map((e) => e.cases).reduce((a, b) => a > b ? a : b);
    final abnormal = records.where((item) => item.cases >= average * 1.2).toList();

    return TrendSummary(
      records: records,
      latestCases: records.last.cases,
      peakCases: peak,
      averageCases: average,
      abnormalPoints: abnormal,
    );
  }

  Map<String, int> latestRegionBreakdown({
    required List<DiseaseTrendRecord> dataset,
    required String disease,
  }) {
    final filtered = dataset.where((record) => record.disease == disease).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (filtered.isEmpty) return {};

    final latestDate = filtered.last.date;
    final latest = filtered.where((record) =>
        record.date.year == latestDate.year &&
        record.date.month == latestDate.month &&
        record.date.day == latestDate.day);

    final result = <String, int>{};
    for (final record in latest) {
      result[record.region] = (result[record.region] ?? 0) + record.cases;
    }
    return result;
  }
}
