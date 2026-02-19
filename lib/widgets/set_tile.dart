import 'package:flutter/material.dart';

import '../models/exercise_set_model.dart';

/// A single set row: weight and reps inputs, optional remove.
class SetTile extends StatefulWidget {
  const SetTile({
    super.key,
    required this.set,
    required this.onChanged,
    this.onRemove,
    this.index,
  });

  final ExerciseSet set;
  final ValueChanged<ExerciseSet> onChanged;
  final VoidCallback? onRemove;
  final int? index;

  @override
  State<SetTile> createState() => _SetTileState();
}

class _SetTileState extends State<SetTile> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight > 0 ? widget.set.weight.toString() : '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(SetTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set != widget.set) {
      _weightController.text =
          widget.set.weight > 0 ? widget.set.weight.toString() : '';
      _repsController.text =
          widget.set.reps > 0 ? widget.set.reps.toString() : '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (widget.index != null)
            SizedBox(
              width: 28,
              child: Text(
                '${widget.index! + 1}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Expanded(
            child: TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                final w = double.tryParse(v) ?? 0;
                widget.onChanged(widget.set.copyWith(weight: w));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                final r = int.tryParse(v) ?? 0;
                widget.onChanged(widget.set.copyWith(reps: r));
              },
            ),
          ),
          if (widget.onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: widget.onRemove,
            ),
        ],
      ),
    );
  }
}
