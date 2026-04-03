import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beautiful_welcome/core/models/fitness_models.dart';
import 'package:beautiful_welcome/core/theme/app_colors.dart';
import 'package:beautiful_welcome/features/routines/providers/routine_provider.dart';
import 'package:beautiful_welcome/features/tracking/providers/tracking_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RoutinesDashboardScreen extends ConsumerWidget {
  const RoutinesDashboardScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, Routine routine, AppLocalizations? l10n) async {
    final trackingLogs = ref.read(trackingProvider);
    final hasTracking = trackingLogs.any((log) => log.routineId == routine.id);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${routine.name}?'),
        content: Text(
          hasTracking 
            ? 'Warning: This routine has been tracked. Deleting it will also remove all related tracking data to maintain consistency. This action cannot be undone.'
            : 'Are you sure you want to delete this routine?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.accent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      ref.read(routineProvider.notifier).deleteRoutine(routine.id);
      if (hasTracking) {
         ref.read(trackingProvider.notifier).deleteLogsForRoutine(routine.id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routineProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: routines.isEmpty
          ? Center(
              child: Text(
                l10n?.noRoutines ?? 'No routines defined yet.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Hero(
                    tag: 'routine_card_${routine.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () {
                          context.push('/track-workout/${routine.id}');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        routine.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (routine.mainObjective.isNotEmpty)
                                        Text(
                                          '${l10n?.mainObjective ?? 'Objective'}: ${routine.mainObjective}',
                                          style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        routine.description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Icon(Icons.fitness_center, color: AppColors.accent, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${routine.days.length} Days',
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.accent),
                                      onPressed: () => context.push('/create-routine?id=${routine.id}'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _confirmDelete(context, ref, routine, l10n),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-routine'),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(l10n?.newRoutine ?? 'NEW ROUTINE', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
