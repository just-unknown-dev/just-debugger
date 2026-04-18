import 'package:flutter/material.dart';

import '../core/just_debugger_controller.dart';

class EcsDebuggerPanel extends StatelessWidget {
  const EcsDebuggerPanel({super.key, required this.controller});

  final JustDebuggerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.snapshot;
        final health = controller.health;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'ECS Inspector',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoTile(
                      label: 'Entities',
                      value: '${snapshot.entityCount}',
                    ),
                    _InfoTile(
                      label: 'Active entities',
                      value: '${snapshot.activeEntityCount}',
                    ),
                    _InfoTile(
                      label: 'Systems',
                      value: '${snapshot.systemCount}',
                    ),
                    _InfoTile(
                      label: 'Active systems',
                      value: '${snapshot.activeSystemCount}',
                    ),
                    _InfoTile(
                      label: 'Archetypes',
                      value: '${snapshot.archetypeCount}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Component usage',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.componentUsage.isEmpty)
                      const Text('No component usage has been published yet.')
                    else
                      for (final entry in snapshot.componentUsage.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${entry.key}: ${entry.value}'),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System timings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.systemTimesMs.isEmpty)
                      const Text('No system timing data available yet.')
                    else
                      for (final entry in snapshot.systemTimesMs.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${entry.key}: ${entry.value.toStringAsFixed(2)} ms',
                          ),
                        ),
                  ],
                ),
              ),
            ),
            if (health.hasWarnings) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.orange.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Warnings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      for (final message in health.messages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $message'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
