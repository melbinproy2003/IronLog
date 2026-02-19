import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workout_provider.dart';

/// Displays coach suggestions from the coach engine (via provider).
class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(coachSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: suggestionsAsync.when(
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return const Center(
              child: Text('Log workouts to get suggestions.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(coachSuggestionsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      s.priority >= 2
                          ? Icons.warning_amber_rounded
                          : Icons.lightbulb_outline,
                      color: s.priority >= 2
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    title: Text(s.text),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
