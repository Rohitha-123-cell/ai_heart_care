import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../services/ai_service.dart';
import '../../services/disease_trend_service.dart';

class DiseaseTrendDashboardScreen extends StatefulWidget {
  const DiseaseTrendDashboardScreen({super.key});

  @override
  State<DiseaseTrendDashboardScreen> createState() => _DiseaseTrendDashboardScreenState();
}

class _DiseaseTrendDashboardScreenState extends State<DiseaseTrendDashboardScreen> {
  final DiseaseTrendService _trendService = DiseaseTrendService();
  final AIService _aiService = AIService();

  late final List<DiseaseTrendRecord> _dataset;
  String _selectedDisease = DiseaseTrendService.diseases.first;
  String _selectedRegion = DiseaseTrendService.regions.first;
  int _selectedDays = 14;
  bool _isGeneratingSummary = false;
  String _summary = '';

  @override
  void initState() {
    super.initState();
    _dataset = _trendService.loadLocalDataset();
  }

  Future<void> _generateSummary(TrendSummary summary) async {
    setState(() {
      _isGeneratingSummary = true;
    });

    final response = await _aiService.summarizeDiseaseTrend(
      disease: _selectedDisease,
      region: _selectedRegion,
      latestCases: summary.latestCases,
      peakCases: summary.peakCases,
      averageCases: summary.averageCases,
      abnormalDays: summary.abnormalPoints.length,
    );

    if (!mounted) return;
    setState(() {
      _summary = response;
      _isGeneratingSummary = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _trendService.buildSummary(
      dataset: _dataset,
      disease: _selectedDisease,
      region: _selectedRegion,
      days: _selectedDays,
    );
    final regionBreakdown = _trendService.latestRegionBreakdown(
      dataset: _dataset,
      disease: _selectedDisease,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF071A26),
              Color(0xFF0F3A4A),
              Color(0xFF155E75),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: SingleChildScrollView(
                padding: Responsive.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildFilters(context),
                    const SizedBox(height: 20),
                    _buildStats(summary),
                    const SizedBox(height: 20),
                    _buildTrendChart(summary),
                    const SizedBox(height: 20),
                    _buildRegionChart(regionBreakdown),
                    const SizedBox(height: 20),
                    _buildAbnormalDays(summary),
                    const SizedBox(height: 20),
                    _buildAiSummary(summary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disease Trend Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Local outbreak trend analysis with charting, filters, and AI summary.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _dropdownCard(
            label: 'Disease',
            value: _selectedDisease,
            items: DiseaseTrendService.diseases,
            onChanged: (value) => setState(() => _selectedDisease = value!),
          ),
          _dropdownCard(
            label: 'Region',
            value: _selectedRegion,
            items: DiseaseTrendService.regions,
            onChanged: (value) => setState(() => _selectedRegion = value!),
          ),
          _dropdownCard(
            label: 'Window',
            value: '$_selectedDays days',
            items: const ['7 days', '14 days', '30 days'],
            onChanged: (value) => setState(() => _selectedDays = int.parse(value!.split(' ').first)),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 180),
            child: ElevatedButton.icon(
              onPressed: _isGeneratingSummary
                  ? null
                  : () => _generateSummary(
                        _trendService.buildSummary(
                          dataset: _dataset,
                          disease: _selectedDisease,
                          region: _selectedRegion,
                          days: _selectedDays,
                        ),
                      ),
              icon: _isGeneratingSummary
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_graph),
              label: Text(_isGeneratingSummary ? 'Generating...' : 'Gemini Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownCard({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E2E9)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStats(TrendSummary summary) {
    final cards = [
      _StatCardData('Latest Cases', '${summary.latestCases}', const Color(0xFF0F766E)),
      _StatCardData('Peak Cases', '${summary.peakCases}', const Color(0xFFDC2626)),
      _StatCardData('Average Cases', summary.averageCases.toStringAsFixed(1), const Color(0xFF2563EB)),
      _StatCardData('Abnormal Days', '${summary.abnormalPoints.length}', const Color(0xFFF59E0B)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000 ? 4 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (card) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.label, style: const TextStyle(color: Color(0xFF52606D), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Text(
                          card.value,
                          style: TextStyle(color: card.color, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildTrendChart(TrendSummary summary) {
    final spots = <FlSpot>[];
    for (var i = 0; i < summary.records.length; i++) {
      spots.add(FlSpot(i.toDouble(), summary.records[i].cases.toDouble()));
    }

    final maxY = summary.records.isEmpty
        ? 10.0
        : summary.records.map((e) => e.cases.toDouble()).reduce((a, b) => a > b ? a : b) + 10;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trend Curve',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF102A43)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Filtered local dataset plotted over time with abnormal spikes highlighted.',
            style: TextStyle(color: Color(0xFF52606D)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFE2E8F0)),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF52606D)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= summary.records.length) return const SizedBox.shrink();
                        final date = summary.records[index].date;
                        return Text(
                          '${date.month}/${date.day}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF52606D)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF0F766E),
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final point = summary.records[index];
                        final isAbnormal = summary.abnormalPoints.any(
                          (item) => item.date == point.date && item.cases == point.cases,
                        );
                        return FlDotCirclePainter(
                          radius: isAbnormal ? 5 : 3.5,
                          color: isAbnormal ? const Color(0xFFDC2626) : const Color(0xFF0F766E),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionChart(Map<String, int> data) {
    final entries = data.entries.toList();
    final maxValue = entries.isEmpty ? 10.0 : entries.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b) + 10;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Region Comparison',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF102A43)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: maxValue,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            entries[index].key.replaceAll(' Zone', ''),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF52606D)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(entries.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entries[index].value.toDouble(),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0F766E)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbnormalDays(TrendSummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Abnormal Trend Highlights',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF102A43)),
          ),
          const SizedBox(height: 12),
          if (summary.abnormalPoints.isEmpty)
            const Text('No abnormal peaks found for the selected filter range.')
          else
            ...summary.abnormalPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${point.date.month}/${point.date.day}: ${point.cases} cases recorded in the selected trend window.',
                        style: const TextStyle(color: Color(0xFF334E68)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiSummary(TrendSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gemini Insight',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF102A43)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate a quick AI summary from the filtered disease trend data.',
            style: TextStyle(color: Color(0xFF52606D)),
          ),
          const SizedBox(height: 16),
          if (_summary.isEmpty)
            TextButton.icon(
              onPressed: _isGeneratingSummary ? null : () => _generateSummary(summary),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Create summary'),
            )
          else
            Text(
              _summary,
              style: const TextStyle(color: Color(0xFF334E68), height: 1.6),
            ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final Color color;

  const _StatCardData(this.label, this.value, this.color);
}
