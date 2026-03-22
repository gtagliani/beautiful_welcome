import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beautiful_welcome/core/theme/app_colors.dart';
import 'package:beautiful_welcome/features/profile/presentation/providers/profile_provider.dart';
import 'package:beautiful_welcome/features/profile/domain/models/weight_entry.dart';

class HealthDashboardScreen extends ConsumerStatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  ConsumerState<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends ConsumerState<HealthDashboardScreen> {
  Future<void> _addOrEditWeightEntry(WeightEntry? entry) async {
    final l10n = AppLocalizations.of(context);
    final isEditing = entry != null;
    DateTime selectedDate = entry?.date ?? DateTime.now();
    final weightController = TextEditingController(text: entry?.weight.toString() ?? '');
    final profile = ref.read(profileProvider);

    final result = await showDialog<WeightEntry>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              title: Text(isEditing ? (l10n?.editWeight ?? 'Edit Weight') : (l10n?.addWeight ?? 'Add Weight')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.isAfter(now) ? now : selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n?.date ?? 'Date',
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${l10n?.weight ?? 'Weight'} (${profile.weightUnit == 'lbs' ? l10n?.pounds ?? 'lbs' : l10n?.kilos ?? 'kg'})',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: () {
                    final weightValue = double.tryParse(weightController.text);
                    if (weightValue != null) {
                      final newEntry = WeightEntry(
                        id: isEditing ? entry.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        date: selectedDate,
                        weight: weightValue,
                      );
                      Navigator.pop(context, newEntry);
                    }
                  },
                  child: Text(l10n?.save ?? 'Save', style: const TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final updatedHistory = List<WeightEntry>.from(profile.weightHistory);
      if (isEditing) {
        final index = updatedHistory.indexWhere((e) => e.id == result.id);
        if (index != -1) {
          updatedHistory[index] = result;
        }
      } else {
        updatedHistory.add(result);
      }
      updatedHistory.sort((a, b) => b.date.compareTo(a.date));
      
      ref.read(profileProvider.notifier).saveProfile(
        profile.copyWith(weightHistory: updatedHistory),
      );
    }
  }

  void _deleteWeightEntry(WeightEntry entry) {
    final profile = ref.read(profileProvider);
    final updatedHistory = List<WeightEntry>.from(profile.weightHistory);
    updatedHistory.removeWhere((e) => e.id == entry.id);
    ref.read(profileProvider.notifier).saveProfile(
      profile.copyWith(weightHistory: updatedHistory),
    );
  }

  Widget _buildGraph(List<WeightEntry> history, String unit) {
    if (history.isEmpty) return const SizedBox();

    final sortedHistory = List<WeightEntry>.from(history)..sort((a, b) => a.date.compareTo(b.date));
    double minWeight = double.infinity;
    double maxWeight = -double.infinity;

    final spots = sortedHistory.asMap().entries.map((entry) {
      final index = entry.key;
      final weight = entry.value.weight;
      if (weight < minWeight) minWeight = weight;
      if (weight > maxWeight) maxWeight = weight;
      return FlSpot(index.toDouble(), weight);
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
               sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedHistory.length && (index == 0 || index == sortedHistory.length -1 || index % (sortedHistory.length~/3 + 1) == 0)) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('MM/dd').format(sortedHistory[index].date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                      );
                    }
                    return const Text('');
                  },
               ),
            ),
            leftTitles: AxisTitles(
               sideTitles: SideTitles(
                 showTitles: true,
                 reservedSize: 40,
                 getTitlesWidget: (value, meta) {
                   return Text(value.toStringAsFixed(1), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10));
                 },
               ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: (minWeight - 5).clamp(0, double.infinity),
          maxY: maxWeight + 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final history = profile.weightHistory;
    final l10n = AppLocalizations.of(context);
    final unitString = profile.weightUnit == 'lbs' ? (l10n?.pounds ?? 'lbs') : (l10n?.kilos ?? 'kg');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.health ?? 'Health'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (history.isNotEmpty) ...[
              const Text(
                'Weight Progression',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildGraph(history, profile.weightUnit),
              const SizedBox(height: 32),
            ],
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.weightTracking ?? 'Weight Tracking',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.accent),
                  onPressed: () => _addOrEditWeightEntry(null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    l10n?.noWeightData ?? 'No weight data yet.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final entry = history[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.monitor_weight, color: AppColors.accent),
                      title: Text('${entry.weight} $unitString', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(entry.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _addOrEditWeightEntry(entry),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.orange),
                            onPressed: () => _deleteWeightEntry(entry),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
