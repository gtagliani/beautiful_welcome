import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});

class ProfileNotifier extends StateNotifier<UserProfile> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository)
      : super(UserProfile(name: '', birthDate: null, weightHistory: [], localeCode: 'system', weightUnit: 'kg')) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final profile = await _repository.loadProfile();
    if (profile != null) {
      state = profile;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _repository.saveProfile(profile);
    state = profile;
  }

  Future<void> clearProfile() async {
    await _repository.clearProfile();
    state = UserProfile(name: '', birthDate: null, weightHistory: [], localeCode: 'system', weightUnit: 'kg');
  }

  Future<void> updateLocale(String localeCode) async {
    final newProfile = state.copyWith(localeCode: localeCode);
    await saveProfile(newProfile);
  }

  Future<void> updateWeightUnit(String weightUnit) async {
    final newProfile = state.copyWith(weightUnit: weightUnit);
    await saveProfile(newProfile);
  }
}
