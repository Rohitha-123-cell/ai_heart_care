import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


import '../../core/utils/responsive.dart';
import '../../services/menstrual_cycle_service.dart';

class MenstrualCycleScreen extends StatefulWidget {
  const MenstrualCycleScreen({super.key});

  @override
  State<MenstrualCycleScreen> createState() => _MenstrualCycleScreenState();
}

class _MenstrualCycleScreenState extends State<MenstrualCycleScreen> {
  List<CycleRecord> _cycleRecords = [];
  List<SymptomEntry> _symptomEntries = [];
  bool _isLoading = true;

  DateTime? _newPeriodStart;
  DateTime? _newPeriodEnd;
  DateTime _symptomDate = DateTime.now();
  double _recordTemperature = 36.8;
  double _symptomTemperature = 36.9;
  String _selectedCondition = 'Stable';
  String _selectedFlow = 'Moderate';
  String _selectedSymptomFlow = 'Moderate';
  String _bodyChanges = '';
  String _symptomNotes = '';
  final Set<String> _selectedSymptoms = {'Cramps'};
  bool _periodReminders = true;
  bool _ovulationReminders = true;
  bool _medicationReminders = false;
  bool _pregnancyMode = false;
  bool _birthControlTracking = true;

  static const List<String> _flowLevels = ['Light', 'Moderate', 'Heavy'];
  static const List<String> _healthConditions = [
    'Stable',
    'Low energy',
    'High stress',
    'Painful cycle',
    'Recovering',
  ];

  CyclePrediction get _prediction => MenstrualCycleService.generatePrediction(
    records: _cycleRecords,
    symptoms: _symptomEntries,
    periodReminderEnabled: _periodReminders,
    ovulationReminderEnabled: _ovulationReminders,
    medicationReminderEnabled: _medicationReminders,
    pregnancyModeEnabled: _pregnancyMode,
    birthControlEnabled: _birthControlTracking,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cycles = await MenstrualCycleService.loadCycleRecords();
    final symptoms = await MenstrualCycleService.loadSymptomEntries();
    if (!mounted) return;
    setState(() {
      _cycleRecords = cycles;
      _symptomEntries = symptoms;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF240046), Color(0xFF5A189A), Color(0xFFE76F51)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final prediction = _prediction;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF240046), Color(0xFF5A189A), Color(0xFFE76F51)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              child: SingleChildScrollView(
                padding: Responsive.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildHero(prediction, isDesktop),
                    const SizedBox(height: 20),
                    _buildStatGrid(prediction),
                    const SizedBox(height: 20),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCycleEntryCard(context)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSymptomEntryCard(context)),
                        ],
                      )
                    else ...[
                      _buildCycleEntryCard(context),
                      const SizedBox(height: 16),
                      _buildSymptomEntryCard(context),
                    ],
                    const SizedBox(height: 20),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCycleHistoryCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildChartsCard(prediction)),
                        ],
                      )
                    else ...[
                      _buildCycleHistoryCard(),
                      const SizedBox(height: 16),
                      _buildChartsCard(prediction),
                    ],
                    const SizedBox(height: 20),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildReminderCard(prediction)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildInsightsCard(prediction)),
                        ],
                      )
                    else ...[
                      _buildReminderCard(prediction),
                      const SizedBox(height: 16),
                      _buildInsightsCard(prediction),
                    ],
                    const SizedBox(height: 20),
                    _buildSupportCard(context),
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
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Women wellness tracker',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Menstrual Cycle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(CyclePrediction prediction, bool isDesktop) {
    final content = [
      _glassMetric(
        title: 'Next period',
        value: _formatDate(prediction.nextPeriodStart),
        detail: 'Estimated based on recent cycle history',
      ),
      _glassMetric(
        title: 'Ovulation day',
        value: _formatDate(prediction.ovulationDay),
        detail: 'Best estimate from cycle-length pattern',
      ),
      _glassMetric(
        title: 'Fertile window',
        value:
            '${_formatShortDate(prediction.fertileWindowStart)} - ${_formatShortDate(prediction.fertileWindowEnd)}',
        detail: 'Useful for planning or pregnancy tracking',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildHeroText(prediction)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (final item in content) ...[
                        item,
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroText(prediction),
                const SizedBox(height: 16),
                ...content,
              ],
            ),
    );
  }

  Widget _buildHeroText(CyclePrediction prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Cycle forecast and daily log',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Track periods, symptoms, temperature, and body changes with prediction support.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          prediction.irregularCycleDetected
              ? 'Recent entries suggest some cycle variation. Keep logging consistently for stronger predictions.'
              : 'Your recent cycle history looks stable enough for next-period and ovulation estimates.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _glassMetric({
    required String title,
    required String value,
    required String detail,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(detail, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatGrid(CyclePrediction prediction) {
    final latest = _cycleRecords.isNotEmpty ? _cycleRecords.last : null;
    final stats = [
      _StatData(
        title: 'Average cycle',
        value: '${prediction.averageCycleLength} days',
        color: const Color(0xFF7C3AED),
      ),
      _StatData(
        title: 'Period length',
        value: '${prediction.averagePeriodLength} days',
        color: const Color(0xFFE11D48),
      ),
      _StatData(
        title: 'Temperature',
        value: latest != null
            ? '${latest.averageTemperature.toStringAsFixed(1)} °C'
            : '-- °C',
        color: const Color(0xFF2563EB),
      ),
      _StatData(
        title: 'Current flow',
        value: latest?.flowIntensity ?? '--',
        color: const Color(0xFFF97316),
      ),
      _StatData(
        title: 'Condition',
        value: latest?.healthCondition ?? '--',
        color: const Color(0xFF0F766E),
      ),
      _StatData(
        title: 'Cycle status',
        value: prediction.irregularCycleDetected ? 'Irregular' : 'Regular',
        color: prediction.irregularCycleDetected
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: stats.map((stat) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: stat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      stat.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stat.value,
                      style: const TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCycleEntryCard(BuildContext context) {
    return _surfaceCard(
      title: 'Add cycle dates',
      subtitle: 'Log start and end dates, flow, temperature, and how you felt.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _datePickerTile(
            label: 'Period start',
            value: _newPeriodStart,
            onTap: () async {
              final selected = await _pickDate(
                _newPeriodStart ?? DateTime.now(),
              );
              if (selected != null) setState(() => _newPeriodStart = selected);
            },
          ),
          const SizedBox(height: 12),
          _datePickerTile(
            label: 'Period end',
            value: _newPeriodEnd,
            onTap: () async {
              final selected = await _pickDate(_newPeriodEnd ?? DateTime.now());
              if (selected != null) setState(() => _newPeriodEnd = selected);
            },
          ),
          const SizedBox(height: 14),
          _dropdownField(
            label: 'Flow intensity',
            value: _selectedFlow,
            items: _flowLevels,
            onChanged: (value) => setState(() => _selectedFlow = value!),
          ),
          const SizedBox(height: 14),
          _dropdownField(
            label: 'Health condition',
            value: _selectedCondition,
            items: _healthConditions,
            onChanged: (value) => setState(() => _selectedCondition = value!),
          ),
          const SizedBox(height: 14),
          Text(
            'Average body temperature: ${_recordTemperature.toStringAsFixed(1)} C',
          ),
          Slider(
            value: _recordTemperature,
            min: 35.5,
            max: 38.5,
            divisions: 30,
            label: _recordTemperature.toStringAsFixed(1),
            onChanged: (value) => setState(() => _recordTemperature = value),
          ),
          ElevatedButton.icon(
            onPressed: _addCycleRecord,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Save cycle record'),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomEntryCard(BuildContext context) {
    return _surfaceCard(
      title: 'Daily symptom log',
      subtitle: 'Track cramps, mood swings, fatigue, flow, and body changes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _datePickerTile(
            label: 'Symptom date',
            value: _symptomDate,
            onTap: () async {
              final selected = await _pickDate(_symptomDate);
              if (selected != null) setState(() => _symptomDate = selected);
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MenstrualCycleService.commonSymptoms.map((symptom) {
              final selected = _selectedSymptoms.contains(symptom);
              return FilterChip(
                label: Text(symptom),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      _selectedSymptoms.remove(symptom);
                    } else {
                      _selectedSymptoms.add(symptom);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _dropdownField(
            label: 'Flow',
            value: _selectedSymptomFlow,
            items: _flowLevels,
            onChanged: (value) => setState(() => _selectedSymptomFlow = value!),
          ),
          const SizedBox(height: 14),
          Text('Body temperature: ${_symptomTemperature.toStringAsFixed(1)} C'),
          Slider(
            value: _symptomTemperature,
            min: 35.5,
            max: 38.5,
            divisions: 30,
            label: _symptomTemperature.toStringAsFixed(1),
            onChanged: (value) => setState(() => _symptomTemperature = value),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => _bodyChanges = value,
            decoration: const InputDecoration(
              labelText: 'Body changes',
              hintText: 'Bloating, acne, tenderness, cravings...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => _symptomNotes = value,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Anything important to remember today',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addSymptomEntry,
            icon: const Icon(Icons.favorite_border_rounded),
            label: const Text('Save symptom entry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleHistoryCard() {
    final recentRecords = [..._cycleRecords]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return _surfaceCard(
      title: 'Past 2 months cycle history',
      subtitle:
          'Recent records improve cycle-length and fertile-window accuracy.',
      child: Column(
        children: recentRecords.take(3).map((record) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EAF6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBE185D).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFFBE185D),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatShortDate(record.startDate)} - ${_formatShortDate(record.endDate)}',
                        style: const TextStyle(
                          color: Color(0xFF102A43),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.periodLength} days • ${record.flowIntensity} flow • ${record.healthCondition}',
                        style: const TextStyle(color: Color(0xFF52606D)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${record.averageTemperature.toStringAsFixed(1)} C',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartsCard(CyclePrediction prediction) {
    final cycleLengths = prediction.cycleLengths.isEmpty
        ? [prediction.averageCycleLength]
        : prediction.cycleLengths;
    final temperatureData = _cycleRecords
        .map((record) => record.averageTemperature)
        .toList();

    return _surfaceCard(
      title: 'Reports and charts',
      subtitle:
          'See cycle pattern history, flow consistency, and temperature trends.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cycle length pattern',
            style: TextStyle(
              color: Color(0xFF102A43),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF52606D),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'C${value.toInt() + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF52606D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                barGroups: List.generate(cycleLengths.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: cycleLengths[index].toDouble(),
                        width: 20,
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFE11D48)],
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
          const SizedBox(height: 18),
          const Text(
            'Temperature trend',
            style: TextStyle(
              color: Color(0xFF102A43),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 35.5,
                maxY: 38.5,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF52606D),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        'M${value.toInt() + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF52606D),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF2563EB),
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF2563EB),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    spots: List.generate(
                      temperatureData.length,
                      (index) =>
                          FlSpot(index.toDouble(), temperatureData[index]),
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

  Widget _buildReminderCard(CyclePrediction prediction) {
    return _surfaceCard(
      title: 'Reminder notifications',
      subtitle: 'Period, ovulation, PMS, and medication reminder planning.',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Upcoming period alerts'),
            value: _periodReminders,
            onChanged: (value) => setState(() => _periodReminders = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ovulation reminders'),
            value: _ovulationReminders,
            onChanged: (value) => setState(() => _ovulationReminders = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Medication tracking'),
            value: _medicationReminders,
            onChanged: (value) => setState(() => _medicationReminders = value),
          ),
          const Divider(height: 24),
          ...prediction.reminders.map((reminder) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            color: Color(0xFF102A43),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.detail,
                          style: const TextStyle(color: Color(0xFF52606D)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatShortDate(reminder.scheduledFor),
                    style: const TextStyle(
                      color: Color(0xFFE11D48),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(CyclePrediction prediction) {
    return _surfaceCard(
      title: 'Smart insights',
      subtitle:
          'PMS alerts, irregular-cycle detection, and personalized wellness notes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pregnancy mode'),
            subtitle: const Text(
              'Focus predictions around missed periods and fertile timing.',
            ),
            value: _pregnancyMode,
            onChanged: (value) => setState(() => _pregnancyMode = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Birth control tracking'),
            subtitle: const Text(
              'Use reminders and insights for adherence support.',
            ),
            value: _birthControlTracking,
            onChanged: (value) => setState(() => _birthControlTracking = value),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: prediction.irregularCycleDetected
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              prediction.irregularCycleDetected
                  ? 'Irregular cycle detection is active because recent cycle lengths vary more than expected.'
                  : 'Cycle consistency looks healthy across recent entries.',
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'PMS alert window starts on ${_formatDate(prediction.pmsAlertDate)}.',
            style: const TextStyle(
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...prediction.insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        color: Color(0xFF52606D),
                        height: 1.45,
                      ),
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

  Widget _buildSupportCard(BuildContext context) {
    return _surfaceCard(
      title: 'Doctor consultation support',
      subtitle:
          'Use this when pain, heavy bleeding, missed periods, or irregular cycles become concerning.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested reasons to seek support:',
            style: TextStyle(
              color: Color(0xFF102A43),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text('- Bleeding longer than 7 days or unusually heavy flow'),
          const Text('- Severe cramps, fainting, or very high fatigue'),
          const Text('- Repeatedly missed or highly irregular cycles'),
          const Text(
            '- Unusual temperature or symptom patterns while in pregnancy mode',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Doctor consultation summary prepared from your recent cycle logs.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text('Prepare consult summary'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You can connect this screen to hospital or telehealth support next.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.local_hospital_outlined),
                label: const Text('Consultation support'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _surfaceCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF102A43),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF52606D), height: 1.45),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _datePickerTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF7C3AED)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF52606D))),
                  const SizedBox(height: 4),
                  Text(
                    value == null ? 'Select date' : _formatDate(value),
                    style: const TextStyle(
                      color: Color(0xFF102A43),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF52606D)),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
  }

  Future<void> _addCycleRecord() async {
    if (_newPeriodStart == null || _newPeriodEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both period start and end dates.')),
      );
      return;
    }
    if (_newPeriodEnd!.isBefore(_newPeriodStart!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period end date must be after the start date.')),
      );
      return;
    }

    final record = CycleRecord(
      startDate: _newPeriodStart!,
      endDate: _newPeriodEnd!,
      averageTemperature: _recordTemperature,
      healthCondition: _selectedCondition,
      flowIntensity: _selectedFlow,
    );

    await MenstrualCycleService.saveCycleRecord(record);

    setState(() {
      _cycleRecords.add(record);
      _newPeriodStart = null;
      _newPeriodEnd = null;
      _recordTemperature = 36.8;
      _selectedCondition = 'Stable';
      _selectedFlow = 'Moderate';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle record saved successfully.')),
      );
    }
  }

  Future<void> _addSymptomEntry() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one symptom to continue.')),
      );
      return;
    }

    final entry = SymptomEntry(
      date: _symptomDate,
      symptoms: _selectedSymptoms.toList()..sort(),
      flowIntensity: _selectedSymptomFlow,
      bodyTemperature: _symptomTemperature,
      bodyChanges: _bodyChanges.trim().isEmpty
          ? 'No major body changes noted'
          : _bodyChanges.trim(),
      notes: _symptomNotes.trim(),
    );

    await MenstrualCycleService.saveSymptomEntry(entry);

    setState(() {
      _symptomEntries.add(entry);
      _symptomDate = DateTime.now();
      _selectedSymptoms
        ..clear()
        ..add('Cramps');
      _selectedSymptomFlow = 'Moderate';
      _symptomTemperature = 36.9;
      _bodyChanges = '';
      _symptomNotes = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptom entry saved successfully.')),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _StatData {
  final String title;
  final String value;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.color,
  });
}
