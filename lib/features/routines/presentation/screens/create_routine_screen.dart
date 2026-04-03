import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:beautiful_welcome/core/models/fitness_models.dart';
import 'package:beautiful_welcome/core/theme/app_colors.dart';
import 'package:beautiful_welcome/features/routines/providers/routine_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateRoutineScreen extends ConsumerStatefulWidget {
  final String? routineId;
  const CreateRoutineScreen({super.key, this.routineId});

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class ExerciseForm {
  String? id;
  final TextEditingController name = TextEditingController();
  final TextEditingController link = TextEditingController();
  final TextEditingController desc = TextEditingController();
  final TextEditingController sets = TextEditingController(text: '3');
  final TextEditingController restTime = TextEditingController(text: '1.5');
  List<String> pictures = [];
}

class DayForm {
  String? id;
  final TextEditingController name = TextEditingController();
  List<ExerciseForm> exercises = [ExerciseForm()];
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mainObjectiveController = TextEditingController();
  final _descController = TextEditingController();
  List<DayForm> _days = [DayForm()..name.text = 'Day 1'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.routineId != null) {
        final routines = ref.read(routineProvider);
        try {
          final routine = routines.firstWhere((r) => r.id == widget.routineId);
          setState(() {
            _nameController.text = routine.name;
            _mainObjectiveController.text = routine.mainObjective;
            _descController.text = routine.description;
            _days = routine.days.map((d) {
              final dayForm = DayForm()
                ..id = d.id
                ..name.text = d.name;
              dayForm.exercises = d.exercises.map((e) {
                final exForm = ExerciseForm()
                  ..id = e.id
                  ..name.text = e.name
                  ..link.text = e.youtubeLink
                  ..desc.text = e.description
                  ..sets.text = e.sets.toString()
                  ..restTime.text = e.restTime.toString()
                  ..pictures = List.from(e.pictures);
                return exForm;
              }).toList();
              return dayForm;
            }).toList();
          });
        } catch (_) {}
      }
    });
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString() + math.Random().nextInt(1000).toString();

  Future<void> _pickImage(ExerciseForm ex) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        ex.pictures.add(pickedFile.path);
      });
    }
  }

  void _saveRoutine() {
    if (_formKey.currentState!.validate()) {
      final routine = Routine(
        id: widget.routineId ?? _generateId(),
        name: _nameController.text,
        mainObjective: _mainObjectiveController.text,
        description: _descController.text,
        days: _days.asMap().entries.map((dayEntry) {
          final int dayIndex = dayEntry.key;
          final DayForm d = dayEntry.value;
          return RoutineDay(
            id: d.id ?? _generateId(),
            day: dayIndex + 1,
            name: d.name.text,
            exercises: d.exercises.asMap().entries.map((exEntry) {
              final int exIndex = exEntry.key;
              final ExerciseForm e = exEntry.value;
              return WorkoutExercise(
                id: e.id ?? _generateId(),
                sequence: exIndex + 1,
                name: e.name.text,
                youtubeLink: e.link.text,
                description: e.desc.text,
                pictures: e.pictures,
                sets: int.tryParse(e.sets.text) ?? 3,
                restTime: double.tryParse(e.restTime.text) ?? 1.5,
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
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.routineId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'EDIT ROUTINE' : (l10n?.newRoutine ?? 'NEW ROUTINE')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
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
              decoration: InputDecoration(labelText: '${l10n?.name ?? 'Routine Name'}*', hintText: 'e.g., Push/Pull/Legs'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mainObjectiveController,
              decoration: InputDecoration(labelText: '${l10n?.mainObjective ?? 'Main Objective'}*', hintText: 'e.g., Hypertrophy'),
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
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.photo_library, color: AppColors.accent),
                                        onPressed: () => _pickImage(ex),
                                        tooltip: 'Add Picture',
                                      ),
                                      if (day.exercises.length > 1)
                                        InkWell(
                                          onTap: () => setState(() => day.exercises.removeAt(exIndex)),
                                          child: const Icon(Icons.close, size: 24, color: Colors.redAccent),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                              if (ex.pictures.isNotEmpty)
                                SizedBox(
                                  height: 60,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: ex.pictures.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                                        child: Stack(
                                          children: [
                                            Image.file(File(ex.pictures[index]), width: 50, height: 50, fit: BoxFit.cover),
                                            Positioned(
                                              right: 0, top: 0,
                                              child: InkWell(
                                                onTap: () => setState(() => ex.pictures.removeAt(index)),
                                                child: const Icon(Icons.cancel, color: Colors.red, size: 16),
                                              ),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: ex.name,
                                decoration: InputDecoration(labelText: '${l10n?.name ?? 'Exercise Name'}*', hintText: 'e.g., Squat'),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: ex.sets,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(labelText: '${l10n?.sets ?? 'Sets'}*'),
                                      validator: (v) => (v == null || v.isEmpty || int.parse(v) < 1) ? '>= 1 required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: ex.restTime,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(labelText: '${l10n?.restTime ?? 'Rest (minutes)'}*'),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: ex.link,
                                decoration: const InputDecoration(labelText: 'YouTube Link', hintText: 'https://youtube.com/...', icon: Icon(Icons.play_circle_fill, color: Colors.redAccent)),
                              ),
                              const SizedBox(height: 12),
                               TextFormField(
                                controller: ex.desc,
                                decoration: const InputDecoration(labelText: 'Details', hintText: 'Form details'),
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
