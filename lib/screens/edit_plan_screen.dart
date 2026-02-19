import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/plan_day_model.dart';
import '../models/plan_exercise_model.dart';
import '../models/plan_model.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';

/// Screen to edit an existing training plan.
class EditPlanScreen extends ConsumerStatefulWidget {
  const EditPlanScreen({
    super.key,
    required this.planId,
  });

  final String planId;

  @override
  ConsumerState<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends ConsumerState<EditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _planNameController;
  late List<PlanDay> _days;
  final _uuid = const Uuid();
  bool _isLoading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _planNameController = TextEditingController();
    _days = [];
    // Load plan once when screen is created.
    Future.microtask(() async {
      final service = ref.read(planServiceProvider);
      await service.open();
      final plan = service.getPlanById(widget.planId);
      if (!mounted) return;
      if (plan == null) {
        setState(() {
          _loadError = true;
          _isLoading = false;
        });
      } else {
        _loadPlan(plan);
      }
    });
  }

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  void _loadPlan(Plan plan) {
    if (!mounted) return;
    setState(() {
      _planNameController.text = plan.name;
      _days = List.from(plan.days);
      _isLoading = false;
    });
  }

  void _addDay() {
    showDialog<void>(
      context: context,
      builder: (context) => _AddDayDialog(
        onConfirm: (name) {
          if (name.trim().isEmpty) return;
          setState(() {
            _days.add(PlanDay(
              id: _uuid.v4(),
              name: name.trim(),
              dayIndex: _days.length + 1,
              exercises: [],
            ));
          });
        },
      ),
    );
  }

  void _addExercise(int dayIndex) {
    final day = _days[dayIndex];
    final exerciseNamesAsync = ref.read(allExerciseNamesProvider);
    showDialog<void>(
      context: context,
      builder: (context) => _AddExerciseDialog(
        exerciseNames: exerciseNamesAsync.valueOrNull ?? [],
        onConfirm: (exerciseName, sets, minReps, maxReps, startingWeight, increment) {
          setState(() {
            final updatedExercises = [
              ...day.exercises,
              PlanExercise(
                id: _uuid.v4(),
                exerciseName: exerciseName.trim(),
                currentWeight: startingWeight,
                increment: increment,
                sets: sets,
                minReps: minReps,
                maxReps: maxReps,
              ),
            ];
            _days[dayIndex] = day.copyWith(exercises: updatedExercises);
          });
        },
      ),
    );
  }

  void _editExercise(int dayIndex, int exerciseIndex) {
    final day = _days[dayIndex];
    final exercise = day.exercises[exerciseIndex];
    final exerciseNamesAsync = ref.read(allExerciseNamesProvider);
    showDialog<void>(
      context: context,
      builder: (context) => _AddExerciseDialog(
        exerciseNames: exerciseNamesAsync.valueOrNull ?? [],
        initialExercise: exercise,
        onConfirm: (exerciseName, sets, minReps, maxReps, startingWeight, increment) {
          setState(() {
            final updatedExercises = List<PlanExercise>.from(day.exercises);
            updatedExercises[exerciseIndex] = PlanExercise(
              id: exercise.id,
              exerciseName: exerciseName.trim(),
              currentWeight: startingWeight,
              increment: increment,
              sets: sets,
              minReps: minReps,
              maxReps: maxReps,
            );
            _days[dayIndex] = day.copyWith(exercises: updatedExercises);
          });
        },
      ),
    );
  }

  void _deleteDay(int index) {
    setState(() {
      _days.removeAt(index);
      // Reindex remaining days
      for (var i = 0; i < _days.length; i++) {
        _days[i] = _days[i].copyWith(dayIndex: i + 1);
      }
    });
  }

  void _deleteExercise(int dayIndex, int exerciseIndex) {
    setState(() {
      final day = _days[dayIndex];
      final updatedExercises = List<PlanExercise>.from(day.exercises);
      updatedExercises.removeAt(exerciseIndex);
      _days[dayIndex] = day.copyWith(exercises: updatedExercises);
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one day')),
      );
      return;
    }

    for (final day in _days) {
      if (day.exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${day.name} must have at least one exercise')),
        );
        return;
      }
    }

    final plan = Plan(
      id: widget.planId,
      name: _planNameController.text.trim(),
      createdAt: DateTime.now(), // Keep original or update?
      days: _days,
    );

    await ref.read(planNotifierProvider.notifier).savePlan(plan);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Plan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Plan')),
        body: const Center(child: Text('Plan not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Plan'),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _planNameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
                hintText: 'e.g., Push/Pull/Legs',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a plan name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Days',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Day'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_days.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No days yet. Add your first day.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              )
            else
              ..._days.asMap().entries.map((entry) {
                final dayIndex = entry.key;
                final day = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(day.name),
                    subtitle: Text(
                      '${day.exercises.length} exercise${day.exercises.length != 1 ? 's' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteDay(dayIndex),
                      tooltip: 'Delete day',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Exercises',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                TextButton.icon(
                                  onPressed: () => _addExercise(dayIndex),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Exercise'),
                                ),
                              ],
                            ),
                            if (day.exercises.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No exercises yet.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                              )
                            else
                              ...day.exercises.asMap().entries.map((exEntry) {
                                final exIndex = exEntry.key;
                                final ex = exEntry.value;
                                return ListTile(
                                  title: Text(ex.exerciseName),
                                  subtitle: Text(
                                    '${ex.sets} sets × ${ex.minReps}-${ex.maxReps} reps @ ${ex.currentWeight}kg (+${ex.increment}kg)',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _editExercise(dayIndex, exIndex),
                                        tooltip: 'Edit exercise',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _deleteExercise(dayIndex, exIndex),
                                        tooltip: 'Delete exercise',
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// Reuse dialogs from CreatePlanScreen
class _AddDayDialog extends StatefulWidget {
  const _AddDayDialog({required this.onConfirm});

  final void Function(String) onConfirm;

  @override
  State<_AddDayDialog> createState() => _AddDayDialogState();
}

class _AddDayDialogState extends State<_AddDayDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Day'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Day Name',
          hintText: 'e.g., Push Day',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _confirm() {
    widget.onConfirm(_controller.text);
    Navigator.of(context).pop();
  }
}

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog({
    required this.exerciseNames,
    required this.onConfirm,
    this.initialExercise,
  });

  final List<String> exerciseNames;
  final PlanExercise? initialExercise;
  final void Function(String, int, int, int, double, double) onConfirm;

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseNameController = TextEditingController();
  final _setsController = TextEditingController();
  final _minRepsController = TextEditingController();
  final _maxRepsController = TextEditingController();
  final _startingWeightController = TextEditingController();
  final _incrementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialExercise != null) {
      final ex = widget.initialExercise!;
      _exerciseNameController.text = ex.exerciseName;
      _setsController.text = ex.sets.toString();
      _minRepsController.text = ex.minReps.toString();
      _maxRepsController.text = ex.maxReps.toString();
      _startingWeightController.text = ex.currentWeight.toString();
      _incrementController.text = ex.increment.toString();
    } else {
      _setsController.text = '3';
      _minRepsController.text = '8';
      _maxRepsController.text = '12';
      _startingWeightController.text = '0';
      _incrementController.text = '2.5';
    }
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _setsController.dispose();
    _minRepsController.dispose();
    _maxRepsController.dispose();
    _startingWeightController.dispose();
    _incrementController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    widget.onConfirm(
      _exerciseNameController.text,
      int.parse(_setsController.text),
      int.parse(_minRepsController.text),
      int.parse(_maxRepsController.text),
      double.parse(_startingWeightController.text),
      double.parse(_incrementController.text),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialExercise == null ? 'Add Exercise' : 'Edit Exercise'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  final query = textEditingValue.text.toLowerCase();
                  return widget.exerciseNames.where((name) {
                    return name.toLowerCase().contains(query);
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _exerciseNameController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter exercise name';
                      }
                      return null;
                    },
                    onChanged: (value) => _exerciseNameController.text = value,
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Enter valid sets';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _minRepsController,
                      decoration: const InputDecoration(
                        labelText: 'Min Reps',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Enter valid reps';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _maxRepsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Reps',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Enter valid reps';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startingWeightController,
                      decoration: const InputDecoration(
                        labelText: 'Current Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                          return 'Enter valid weight';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _incrementController,
                      decoration: const InputDecoration(
                        labelText: 'Increment (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Enter valid increment';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
