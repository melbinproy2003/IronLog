import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils.dart';
import '../models/plan_model.dart';
import '../providers/plan_provider.dart';
import 'create_plan_screen.dart';
import 'edit_plan_screen.dart';

/// Screen to view all plans, activate, and delete.
class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(allPlansProvider);
    final activePlanIdAsync = ref.watch(activePlanIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No plans yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first plan',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allPlansProvider);
              ref.invalidate(activePlanIdProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return activePlanIdAsync.when(
                  data: (activeId) => _PlanCard(
                    plan: plan,
                    isActive: activeId == plan.id,
                    onTap: () async {
                      await ref
                          .read(planNotifierProvider.notifier)
                          .setActivePlanId(plan.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${plan.name} activated')),
                        );
                      }
                    },
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EditPlanScreen(planId: plan.id),
                        ),
                      );
                    },
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete plan'),
                              content: Text(
                                'Are you sure you want to delete "${plan.name}"? This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (confirmed && context.mounted) {
                        await ref
                            .read(planNotifierProvider.notifier)
                            .deletePlan(plan.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Plan deleted')),
                          );
                        }
                      }
                    },
                  ),
                  loading: () => _PlanCard(
                    plan: plan,
                    isActive: false,
                    onTap: () {},
                    onEdit: () {},
                    onDelete: () {},
                  ),
                  error: (_, __) => _PlanCard(
                    plan: plan,
                    isActive: false,
                    onTap: () {},
                    onEdit: () {},
                    onDelete: () {},
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CreatePlanScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Plan plan;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(plan.name)),
            if (isActive)
              Icon(
                Icons.check_circle,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
          ],
        ),
        subtitle: Text(
          '${plan.days.length} day${plan.days.length != 1 ? 's' : ''} • Created ${formatDateKey(plan.createdAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Edit plan',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Delete plan',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
