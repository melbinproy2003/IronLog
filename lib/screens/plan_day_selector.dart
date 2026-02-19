import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan_model.dart';

/// Widget to select a plan day from a plan.
/// Shows horizontal tabs or dropdown based on screen size.
class PlanDaySelector extends ConsumerWidget {
  const PlanDaySelector({
    super.key,
    required this.plan,
    required this.selectedDayId,
    required this.onDaySelected,
  });

  final Plan plan;
  final String? selectedDayId;
  final ValueChanged<String?> onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plan.days.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use horizontal tabs for better UX
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: plan.days.length,
              itemBuilder: (context, index) {
                final day = plan.days[index];
                final isSelected = day.id == selectedDayId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(day.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onDaySelected(day.id);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
