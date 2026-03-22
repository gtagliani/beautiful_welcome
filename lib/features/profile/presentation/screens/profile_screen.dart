import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_profile.dart';

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
            ],
          ),
        ),
      ),
    );
  }
}
