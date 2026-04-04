import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:beautiful_welcome/core/models/fitness_models.dart';
import 'package:beautiful_welcome/core/theme/app_colors.dart';
import 'package:beautiful_welcome/features/routines/providers/routine_provider.dart';
import 'package:beautiful_welcome/features/tracking/providers/tracking_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _selectedRoutineId;
  String? _selectedDayId;
  String? _selectedExerciseId;

  Widget _buildActivityCard(List<WorkoutLog> logs) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
    
    // Count distinct workout days
    int workoutsLast30Days = 0;
    final last30Days = now.subtract(const Duration(days: 30));
    final distinctDays30 = <String>{};
    for (var log in logs) {
      if (log.status == WorkoutLogStatus.finished && log.date.isAfter(last30Days)) {
        distinctDays30.add('${log.date.year}-${log.date.month}-${log.date.day}');
      }
    }
    workoutsLast30Days = distinctDays30.length;

    // Build Bar Chart Data for last 7 days
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < 7; i++) {
       final day = last7Days[i];
       bool trained = logs.any((log) => 
           log.status == WorkoutLogStatus.finished &&
           log.date.year == day.year && 
           log.date.month == day.month && 
           log.date.day == day.day);
       
       barGroups.add(
         BarChartGroupData(
           x: i,
           barRods: [
             BarChartRodData(
               toY: trained ? 1 : 0.1,
               color: trained ? AppColors.accent : Colors.white12,
               width: 16,
               borderRadius: BorderRadius.circular(4),
             )
           ],
         )
       );
    }

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ACTIVITY OVERVIEW', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Last 30 Days', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('$workoutsLast30Days sessions', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Last 7 Days', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = last7Days[value.toInt()];
                          final text = DateFormat('E').format(day).substring(0, 1);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionChart(List<WorkoutLog> logs, List<Routine> routines) {
    Routine? selectedRoutine;
    try { selectedRoutine = routines.firstWhere((r) => r.id == _selectedRoutineId); } catch (_) {}
    
    RoutineDay? selectedDay;
    if (selectedRoutine != null) {
      try { selectedDay = selectedRoutine.days.firstWhere((d) => d.id == _selectedDayId); } catch (_) {}
    }

    WorkoutExercise? selectedExercise;
    if (selectedDay != null) {
      try { selectedExercise = selectedDay.exercises.firstWhere((e) => e.id == _selectedExerciseId); } catch (_) {}
    }

    // Isolate relevant data
    final chartSpots = <FlSpot>[];
    List<WorkoutLog> filteredLogs = [];
    
    if (selectedExercise != null) {
      filteredLogs = logs.where((log) => 
        log.status == WorkoutLogStatus.finished && 
        log.routineId == selectedRoutine!.id && 
        log.routineDayId == selectedDay!.id
      ).toList();
      
      filteredLogs.sort((a, b) => a.date.compareTo(b.date));

      int xIndex = 0;
      for (var log in filteredLogs) {
        final el = log.exerciseLogs.where((e) => e.exerciseId == selectedExercise!.id).firstOrNull;
        if (el != null && el.finished && el.weight > 0) {
          chartSpots.add(FlSpot(xIndex.toDouble(), el.weight));
          xIndex++;
        }
      }
    }

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WEIGHT PROGRESSION', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            
            // Filters
            DropdownButtonFormField<String>(
              value: _selectedRoutineId,
              hint: const Text('Select Routine'),
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: routines.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
              onChanged: (val) => setState(() { _selectedRoutineId = val; _selectedDayId = null; _selectedExerciseId = null; }),
            ),
            const SizedBox(height: 8),
            if (selectedRoutine != null)
              DropdownButtonFormField<String>(
                value: _selectedDayId,
                hint: const Text('Select Day'),
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                items: selectedRoutine.days.map((d) => DropdownMenuItem(value: d.id, child: Text('Day ${d.day} - ${d.name}'))).toList(),
                onChanged: (val) => setState(() { _selectedDayId = val; _selectedExerciseId = null; }),
              ),
            const SizedBox(height: 8),
            if (selectedDay != null)
              DropdownButtonFormField<String>(
                value: _selectedExerciseId,
                hint: const Text('Select Exercise'),
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                items: selectedDay.exercises.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                onChanged: (val) => setState(() { _selectedExerciseId = val; }),
              ),

            const SizedBox(height: 24),
            
            // Chart
            if (selectedExercise == null)
               const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Select an exercise to view progression.', style: TextStyle(color: AppColors.textSecondary)))),
            if (selectedExercise != null && chartSpots.isEmpty)
               const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No historical data found for this exercise.', style: TextStyle(color: AppColors.textSecondary)))),
            if (selectedExercise != null && chartSpots.isNotEmpty)
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.white12, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide X axis dates for simplicity if small width
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartSpots,
                        isCurved: true,
                        color: AppColors.accent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.accent.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<WorkoutLog> logs, List<Routine> routines) {
    final finishedLogs = logs.where((l) => l.status == WorkoutLogStatus.finished).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (finishedLogs.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No logged sessions yet.', style: TextStyle(color: AppColors.textSecondary))));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('PAST SESSIONS', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        ...finishedLogs.map((log) {
          Routine? r;
          try { r = routines.firstWhere((x) => x.id == log.routineId); } catch (_) {}
          RoutineDay? d;
          if (r != null) {
            try { d = r.days.firstWhere((x) => x.id == log.routineDayId); } catch (_) {}
          }

          final routineName = r?.name ?? 'Deleted Routine';
          final dayName = d != null ? 'Day ${d.day} (${d.name})' : 'Unknown Day';
          
          return Card(
            color: AppColors.background,
            margin: const EdgeInsets.only(bottom: 12),
            shape: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.surface, child: Icon(Icons.check, color: AppColors.accent)),
              title: Text(routineName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text('${DateFormat('MMM d, yyyy').format(log.date)} • $dayName', style: const TextStyle(color: AppColors.textSecondary)),
              trailing: Text('${log.percentage.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(trackingProvider);
    final routines = ref.watch(routineProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ANALYTICS & HISTORY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
          const SizedBox(height: 24),
          _buildActivityCard(logs),
          const SizedBox(height: 16),
          _buildProgressionChart(logs, routines),
          const SizedBox(height: 16),
          _buildHistoryList(logs, routines),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
