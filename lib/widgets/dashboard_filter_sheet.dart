import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils.dart';
import '../models/dashboard_filter_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';

/// Modal bottom sheet for dashboard filter: date range, exercise, plan day, quick ranges.
void showDashboardFilterSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _DashboardFilterSheet(),
  );
}

class _DashboardFilterSheet extends ConsumerStatefulWidget {
  const _DashboardFilterSheet();

  @override
  ConsumerState<_DashboardFilterSheet> createState() =>
      _DashboardFilterSheetState();
}

class _DashboardFilterSheetState extends ConsumerState<_DashboardFilterSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _exerciseName;
  String? _planDayId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final filter = ref.read(dashboardFilterProvider);
      setState(() {
        _startDate = filter.startDate;
        _endDate = filter.endDate;
        _exerciseName = filter.exerciseName;
        _planDayId = filter.planDayId;
      });
    });
  }

  void _apply() {
    ref.read(dashboardFilterProvider.notifier).setFilter(DashboardFilter(
          startDate: _startDate,
          endDate: _endDate,
          exerciseName: _exerciseName?.isEmpty == true ? null : _exerciseName,
          planDayId: _planDayId?.isEmpty == true ? null : _planDayId,
        ));
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _exerciseName = null;
      _planDayId = null;
    });
    ref.read(dashboardFilterProvider.notifier).clearFilter();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExerciseNamesProvider);
    final activePlanAsync = ref.watch(activePlanProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Filter workouts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text(
                      'Quick range',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _QuickRangeChip(
                          label: '7 days',
                          onTap: () {
                            setState(() {
                              final end = DateTime.now();
                              _endDate = end;
                              _startDate = end.subtract(const Duration(days: 7));
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _QuickRangeChip(
                          label: '30 days',
                          onTap: () {
                            setState(() {
                              final end = DateTime.now();
                              _endDate = end;
                              _startDate = end.subtract(const Duration(days: 30));
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _QuickRangeChip(
                          label: '90 days',
                          onTap: () {
                            setState(() {
                              final end = DateTime.now();
                              _endDate = end;
                              _startDate = end.subtract(const Duration(days: 90));
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Date range',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && mounted) {
                                setState(() => _startDate = picked);
                              }
                            },
                            child: Text(
                              _startDate == null
                                  ? 'Start'
                                  : formatDateKey(_startDate!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && mounted) {
                                setState(() => _endDate = picked);
                              }
                            },
                            child: Text(
                              _endDate == null
                                  ? 'End'
                                  : formatDateKey(_endDate!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Exercise',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    exercisesAsync.when(
                      data: (names) {
                        final options = ['All', ...names];
                        final value = _exerciseName == null || _exerciseName!.isEmpty
                            ? 'All'
                            : _exerciseName!;
                        return DropdownButtonFormField<String>(
                          value: options.contains(value) ? value : 'All',
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: options
                              .map((n) => DropdownMenuItem(
                                    value: n,
                                    child: Text(n == 'All' ? 'All exercises' : n),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _exerciseName =
                                  v == null || v == 'All' ? null : v;
                            });
                          },
                        );
                      },
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const Text('Could not load exercises'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Plan day',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    activePlanAsync.when(
                      data: (plan) {
                        if (plan == null || plan.days.isEmpty) {
                          return const Text('No active plan');
                        }
                        final days = plan.days;
                        final options = [
                          (id: null as String?, name: 'All days'),
                          ...days.map((d) => (id: d.id, name: d.name)),
                        ];
                        final currentId = _planDayId;
                        final value = currentId == null || currentId.isEmpty
                            ? null
                            : currentId;
                        return DropdownButtonFormField<String?>(
                          value: value,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: options
                              .map((opt) => DropdownMenuItem<String?>(
                                    value: opt.id,
                                    child: Text(opt.name),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _planDayId = v);
                          },
                        );
                      },
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const Text('No active plan'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clear,
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _apply,
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickRangeChip extends StatelessWidget {
  const _QuickRangeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}
