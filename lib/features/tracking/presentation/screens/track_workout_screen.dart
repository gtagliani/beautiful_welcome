import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  RoutineDay? _selectedDay;
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, TextEditingController> _notesControllers = {};

  @override
  void dispose() {
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    for (var c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initDay(RoutineDay day) {
    setState(() {
      _selectedDay = day;
      _weightControllers.clear();
      _notesControllers.clear();
      for (var ex in day.exercises) {
        _weightControllers[ex.id] = TextEditingController();
        _notesControllers[ex.id] = TextEditingController();
      }
    });
  }

  String _generateId() => "${DateTime.now().millisecondsSinceEpoch}${math.Random().nextInt(1000)}";

  void _saveLog() {
    if (_selectedDay == null) return;
    
    final exerciseLogs = <ExerciseLog>[];
    for (var ex in _selectedDay!.exercises) {
      final weightText = _weightControllers[ex.id]?.text ?? '';
      final weight = double.tryParse(weightText) ?? 0.0;
      final notes = _notesControllers[ex.id]?.text ?? '';
      exerciseLogs.add(ExerciseLog(exerciseId: ex.id, weight: weight, notes: notes));
    }

    final log = WorkoutLog(
      id: _generateId(),
      date: _selectedDate,
      routineId: widget.routineId,
      routineDayId: _selectedDay!.id,
      exerciseLogs: exerciseLogs,
    );
    
    ref.read(trackingProvider.notifier).saveLog(log);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout Logged successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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

  void _showCountdownTimer(double minutes) {
    int remainingSeconds = (minutes * 60).round();
    final totalSeconds = remainingSeconds;
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Timer? timer;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) async {
                if (remainingSeconds > 0) {
                  setStateDialog(() => remainingSeconds--);
                } else {
                  t.cancel();
                  final player = AudioPlayer();
                  await player.play(AssetSource('audio/ding.wav'));
                  if (navigator.canPop()) navigator.pop();
                }
              });

            final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
            final secs = (remainingSeconds % 60).toString().padLeft(2, '0');

            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.accent, width: 2)),
              title: const Center(child: Text('REST TIME', style: TextStyle(color: AppColors.textSecondary, letterSpacing: 2))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Stack(
                     alignment: Alignment.center,
                     children: [
                       SizedBox(
                         width: 150, height: 150,
                         child: CircularProgressIndicator(
                           value: totalSeconds > 0 ? remainingSeconds / totalSeconds : 0,
                           strokeWidth: 8,
                           backgroundColor: Colors.white12,
                           valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                         ),
                       ),
                       Text('$mins:$secs', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                     ]
                   )
                ]
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pop(context);
                    },
                    child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                  )
                )
              ]
            );
          }
        );
      }
    );
  }

  Future<void> _launchYoutube(String url) async {
    if (url.isNotEmpty) {
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
      try {
        if (await canLaunchUrlString(url)) {
          await launchUrlString(url);
        } else {
          _showError('Could not open video link.');
        }
      } catch (e) {
        _showError('Invalid URL format.');
      }
    }
  }
  
  void _showError(String msg) {
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final routines = ref.watch(routineProvider);
    final routine = routines.firstWhere(
      (r) => r.id == widget.routineId,
      orElse: () => Routine(id: '', name: 'Unknown', description: '', mainObjective: '', days: []),
    );

    if (routine.days.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.trackSession ?? 'TRACK SESSION')),
        body: const Center(child: Text('No days defined in this routine.')),
      );
    }

    if (_selectedDay == null && routine.days.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initDay(routine.days.first);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.trackSession ?? 'TRACK SESSION'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
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
              if (routine.mainObjective.isNotEmpty)
                Text(
                  '${l10n?.mainObjective ?? 'Objective'}: ${routine.mainObjective}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              const SizedBox(height: 24),
              
              const Text('SELECT ROUTINE DAY', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RoutineDay>(
                    value: _selectedDay,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    items: routine.days.map((day) {
                      return DropdownMenuItem<RoutineDay>(
                        value: day,
                        child: Text('Day ${day.day}${day.name.isNotEmpty ? ' (${day.name})' : ''}'),
                      );
                    }).toList(),
                    onChanged: (day) {
                      if (day != null) _initDay(day);
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
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
              
              const SizedBox(height: 32),
              
              const Text('EXERCISES', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              
              if (_selectedDay != null)
                ..._selectedDay!.exercises.asMap().entries.map((entry) {
                  final ex = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${ex.sequence}. ${ex.name}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                            if (ex.youtubeLink.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 32),
                                onPressed: () => _launchYoutube(ex.youtubeLink),
                              ),
                          ],
                        ),
                        if (ex.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(ex.description, style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                              child: Text('${l10n?.sets ?? 'Sets'}: ${ex.sets}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showCountdownTimer(ex.restTime),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer, color: AppColors.accent, size: 20),
                                    const SizedBox(width: 6),
                                    Text('${ex.restTime} min', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (ex.pictures.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: ex.pictures.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(ex.pictures[index]), 
                                      width: 80, height: 80, fit: BoxFit.cover, 
                                      errorBuilder: (c, e, s) => Container(color: Colors.white12, width: 80, height: 80, child: const Icon(Icons.broken_image))
                                    ),
                                  )
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('${l10n?.weightUsed ?? 'Weight Used'}:', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _weightControllers[ex.id]!,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 50.5',
                                  suffixText: 'kg/lbs',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _notesControllers[ex.id]!,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: l10n?.notes ?? 'Notes',
                            hintText: 'Observations for this exercise...',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _saveLog,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('SAVE WORKOUT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
