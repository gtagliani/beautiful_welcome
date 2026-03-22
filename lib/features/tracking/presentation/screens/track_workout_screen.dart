import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:beautiful_welcome/core/models/fitness_models.dart';
import 'package:beautiful_welcome/core/theme/app_colors.dart';
import 'package:beautiful_welcome/features/routines/providers/routine_provider.dart';
import 'package:beautiful_welcome/features/tracking/providers/tracking_provider.dart';

class TrackWorkoutScreen extends ConsumerStatefulWidget {
  final String routineId;
  const TrackWorkoutScreen({super.key, required this.routineId});

  @override
  ConsumerState<TrackWorkoutScreen> createState() => _TrackWorkoutScreenState();
}

class _TrackWorkoutScreenState extends ConsumerState<TrackWorkoutScreen> {
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString() + math.Random().nextInt(1000).toString();

  void _saveLog() {
    final log = WorkoutLog(
      id: _generateId(),
      date: _selectedDate,
      routineId: widget.routineId,
      notes: _notesController.text,
    );
    ref.read(trackingProvider.notifier).saveLog(log);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout Logged!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: AppColors.accent,
      ),
    );
    context.pop();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(routineProvider);
    final routine = routines.firstWhere(
      (r) => r.id == widget.routineId,
      orElse: () => Routine(id: '', name: 'Unknown', description: '', days: []),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRACK SESSION'),
      ),
      body: Hero(
        tag: 'routine_card_${routine.id}',
        child: Material(
          type: MaterialType.transparency,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                routine.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              if (routine.description.isNotEmpty) ...[
                Text(
                  routine.description,
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
              ],
              
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Icon(Icons.calendar_month, color: AppColors.accent, size: 28),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('WORKOUT NOTES', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'How did it feel? Any PRs?',
                ),
              ),
              
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _saveLog,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('SAVE WORKOUT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
