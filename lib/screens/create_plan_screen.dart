import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/plan_day_model.dart';
import '../models/plan_exercise_model.dart';
import '../models/plan_model.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';

/// Screen to create a new training plan with days and exercises.
class CreatePlanScreen extends ConsumerStatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final List<PlanDay> _days = [];
  final _uuid = const Uuid();

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
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
      id: _uuid.v4(),
      name: _planNameController.text.trim(),
      createdAt: DateTime.now(),
      days: _days,
    );

    await ref.read(planNotifierProvider.notifier).savePlan(plan);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Plan'),
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
                    subtitle: Text('${day.exercises.length} exercise${day.exercises.length != 1 ? 's' : ''}'),
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
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () => _deleteExercise(dayIndex, exIndex),
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
  });

  final List<String> exerciseNames;
  final void Function(String, int, int, int, double, double) onConfirm;

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseNameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _minRepsController = TextEditingController(text: '8');
  final _maxRepsController = TextEditingController(text: '12');
  final _startingWeightController = TextEditingController(text: '0');
  final _incrementController = TextEditingController(text: '2.5');

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
      title: const Text('Add Exercise'),
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
                        labelText: 'Starting Weight (kg)',
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}
