import 'package:flutter/material.dart';

import '../core/utils.dart';

/// Bar showing the selected date and a button to pick a new date.
class DatePickerBar extends StatelessWidget {
  const DatePickerBar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            formatDateKey(selectedDate),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Change date'),
          ),
        ],
      ),
    );
  }
}
