import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:beautiful_welcome/core/models/fitness_models.dart';
import 'package:beautiful_welcome/core/theme/app_colors.dart';
import 'package:beautiful_welcome/features/routines/providers/routine_provider.dart';

class CreateRoutineScreen extends ConsumerStatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class ExerciseForm {
  final TextEditingController name = TextEditingController();
  final TextEditingController link = TextEditingController();
  final TextEditingController desc = TextEditingController();
}

class DayForm {
  final TextEditingController name = TextEditingController();
  final List<ExerciseForm> exercises = [ExerciseForm()];
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<DayForm> _days = [DayForm()..name.text = 'Day 1'];

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString() + math.Random().nextInt(1000).toString();

  void _saveRoutine() {
    if (_formKey.currentState!.validate()) {
      final routine = Routine(
        id: _generateId(),
        name: _nameController.text,
        description: _descController.text,
        days: _days.map((d) {
          return RoutineDay(
            id: _generateId(),
            name: d.name.text,
            exercises: d.exercises.map((e) {
              return WorkoutExercise(
                id: _generateId(),
                name: e.name.text,
                youtubeLink: e.link.text,
                description: e.desc.text,
              );
            }).toList(),
          );
        }).toList(),
      );

      ref.read(routineProvider.notifier).saveRoutine(routine);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW ROUTINE'),
        actions: [
          IconButton(
            onPressed: _saveRoutine,
            icon: const Icon(Icons.check_circle, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'Routine Name*', hintText: 'e.g., Push/Pull/Legs'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'What is the goal?'),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            const Text('WORKOUT DAYS', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            ..._days.asMap().entries.map((entry) {
              final dayIndex = entry.key;
              final day = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: day.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(labelText: 'Day ${dayIndex + 1} Name'),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          if (_days.length > 1) 
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => setState(() => _days.removeAt(dayIndex)),
                            )
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...day.exercises.asMap().entries.map((exEntry) {
                        final exIndex = exEntry.key;
                        final ex = exEntry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('EXERCISE ${exIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1)),
                                  if (day.exercises.length > 1)
                                    InkWell(
                                      onTap: () => setState(() => day.exercises.removeAt(exIndex)),
                                      child: const Icon(Icons.close, size: 20, color: Colors.redAccent),
                                    )
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: ex.name,
                                decoration: const InputDecoration(labelText: 'Exercise Name*', hintText: 'e.g., Squat'),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: ex.link,
                                decoration: const InputDecoration(labelText: 'YouTube Link', hintText: 'https://youtube.com/...', icon: Icon(Icons.play_circle_fill, color: Colors.redAccent)),
                              ),
                              const SizedBox(height: 12),
                               TextFormField(
                                controller: ex.desc,
                                decoration: const InputDecoration(labelText: 'Details / Sets & Reps', hintText: '4 sets of 10'),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => day.exercises.add(ExerciseForm())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('ADD EXERCISE'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: () => setState(() => _days.add(DayForm()..name.text = 'Day ${_days.length + 1}')),
              icon: const Icon(Icons.add_box),
              label: const Text('ADD NEW DAY'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
