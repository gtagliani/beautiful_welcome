import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../providers/profile_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_profile.dart';
import 'package:beautiful_welcome/features/routines/providers/routine_provider.dart';
import 'package:beautiful_welcome/features/tracking/providers/tracking_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _selectedBirthDate;
  String _selectedLocale = 'system';
  String _selectedWeightUnit = 'kg';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.name);
    _selectedBirthDate = profile.birthDate;
    _selectedLocale = profile.localeCode;
    _selectedWeightUnit = profile.weightUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;

      final updatedProfile = UserProfile(
        name: name,
        birthDate: _selectedBirthDate,
        weightHistory: ref.read(profileProvider).weightHistory,
        localeCode: _selectedLocale,
        weightUnit: _selectedWeightUnit,
      );

      ref.read(profileProvider.notifier).saveProfile(updatedProfile);

      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdated)),
        );
      }
    }
  }

  void _clearProfile() {
    ref.read(profileProvider.notifier).clearProfile();
    setState(() {
      _nameController.clear();
      _selectedBirthDate = null;
      _selectedLocale = 'system';
      _selectedWeightUnit = 'kg';
    });
  }

  Future<void> _exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profile = prefs.getString('user_profile') ?? '{}';
      final routines = prefs.getString('saved_routines') ?? '[]';
      final logs = prefs.getString('saved_logs') ?? '[]';

      final routinesList = json.decode(routines) as List<dynamic>;
      
      final normalizedRoutines = [];
      final normalizedDays = [];
      final normalizedExercises = [];
      
      for (var r in routinesList) {
        final routineMap = Map<String, dynamic>.from(r);
        final routineId = routineMap['id'];
        final currentDays = routineMap['days'] as List<dynamic>? ?? [];
        
        for (var d in currentDays) {
          final dayMap = Map<String, dynamic>.from(d);
          final dayId = dayMap['id'];
          dayMap['routineId'] = routineId; // attach foreign key
          
          final currentExercises = dayMap['exercises'] as List<dynamic>? ?? [];
          for (var ex in currentExercises) {
            final exMap = Map<String, dynamic>.from(ex);
            exMap['routineDayId'] = dayId; // attach foreign key
            normalizedExercises.add(exMap);
          }
          
          dayMap.remove('exercises');
          normalizedDays.add(dayMap);
        }
        
        routineMap.remove('days');
        normalizedRoutines.add(routineMap);
      }

      final Map<String, dynamic> exportData = {
        'user_profile': json.decode(profile),
        'routines': normalizedRoutines,
        'routine_days': normalizedDays,
        'exercises': normalizedExercises,
        'workout_tracking': json.decode(logs),
      };

      final jsonString = json.encode(exportData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      final fileName = 'bbh_backup_${DateTime.now().millisecondsSinceEpoch}';
      
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'json',
        mimeType: MimeType.json,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export downloaded successfully!'), backgroundColor: AppColors.accent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final Map<String, dynamic> importData = json.decode(content);
        
        final prefs = await SharedPreferences.getInstance();
        
        if (importData.containsKey('user_profile')) {
          // Normalize back to string if it was an object in the new export format
          final profileData = importData['user_profile'];
          await prefs.setString('user_profile', profileData is String ? profileData : json.encode(profileData));
        }
        
        if (importData.containsKey('workout_tracking')) {
           final logsData = importData['workout_tracking'];
           await prefs.setString('saved_logs', logsData is String ? logsData : json.encode(logsData));
        } else if (importData.containsKey('saved_logs')) { // legacy
           await prefs.setString('saved_logs', importData['saved_logs']);
        }

        if (importData.containsKey('routines')) {
          // Un-normalize new flattened format back to nested domain model
          final flatsRoutines = List<Map<String, dynamic>>.from((importData['routines'] as List).map((x) => Map<String, dynamic>.from(x)));
          final flatDays = List<Map<String, dynamic>>.from((importData['routine_days'] as List? ?? []).map((x) => Map<String, dynamic>.from(x)));
          final flatExercises = List<Map<String, dynamic>>.from((importData['exercises'] as List? ?? []).map((x) => Map<String, dynamic>.from(x)));
          
          for (var day in flatDays) {
            final dayId = day['id'];
            day['exercises'] = flatExercises.where((e) => e['routineDayId'] == dayId).toList();
            for(var ex in day['exercises']) {
              ex.remove('routineDayId');
            }
          }
          
          for (var routine in flatsRoutines) {
            final rId = routine['id'];
            routine['days'] = flatDays.where((d) => d['routineId'] == rId).toList();
            for(var d in routine['days']) {
              d.remove('routineId');
            }
          }
          
          await prefs.setString('saved_routines', json.encode(flatsRoutines));
        } else if (importData.containsKey('saved_routines')) { // legacy
           await prefs.setString('saved_routines', importData['saved_routines']);
        }

        // Force reload of riverpod providers
        ref.invalidate(profileProvider);
        ref.invalidate(routineProvider);
        ref.invalidate(trackingProvider);

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import successful!'), backgroundColor: AppColors.accent),
          );
          // Update local state variables to match new profile
          final newProfile = ref.read(profileProvider);
          setState(() {
            _nameController.text = newProfile.name;
            _selectedBirthDate = newProfile.birthDate;
            _selectedLocale = newProfile.localeCode;
            _selectedWeightUnit = newProfile.weightUnit;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed or invalid file: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context);
    final titleInfo = l10n?.profile ?? 'Profile';
    final age = _calculateAge(_selectedBirthDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(titleInfo),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearProfile,
            tooltip: 'Clear Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n?.name ?? 'Name',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickBirthDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n?.birthDate ?? 'Birth Date',
                          border: const OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedBirthDate == null
                              ? ''
                              : DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
                        ),
                      ),
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      l10n?.ageLabel(age) ?? 'Age: $age',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ],
              ),
 

              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _selectedLocale,
                decoration: InputDecoration(
                  labelText: l10n?.language ?? 'Language',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'system', child: Text(l10n?.systemDefault ?? 'System Default')),
                  DropdownMenuItem(value: 'en', child: Text(l10n?.english ?? 'English')),
                  DropdownMenuItem(value: 'es', child: Text(l10n?.spanish ?? 'Spanish')),
                  DropdownMenuItem(value: 'pt', child: Text(l10n?.portuguese ?? 'Portuguese')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedLocale = val;
                    });
                    ref.read(profileProvider.notifier).updateLocale(val);
                  }
                },
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _selectedWeightUnit,
                decoration: InputDecoration(
                  labelText: l10n?.weightUnit ?? 'Weight Unit',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'kg', child: Text(l10n?.kilos ?? 'Kilos (kg)')),
                  DropdownMenuItem(value: 'lbs', child: Text(l10n?.pounds ?? 'Pounds (lbs)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedWeightUnit = val;
                    });
                    ref.read(profileProvider.notifier).updateWeightUnit(val);
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saveProfile,
                child: Text(
                  l10n?.save ?? 'Save',
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 48),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              const Text('DATA MANAGEMENT', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                     child: OutlinedButton.icon(
                        onPressed: _exportData,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Export Backup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                     )
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: OutlinedButton.icon(
                        onPressed: _importData,
                        icon: const Icon(Icons.download),
                        label: const Text('Import Backup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                     )
                   ),
                ]
              )
            ],
          ),
        ),
      ),
    );
  }
}
