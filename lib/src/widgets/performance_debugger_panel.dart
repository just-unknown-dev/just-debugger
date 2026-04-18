import 'package:flutter/material.dart';

import '../core/just_debugger_controller.dart';

class PerformanceDebuggerPanel extends StatelessWidget {
  const PerformanceDebuggerPanel({super.key, required this.controller});

  final JustDebuggerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.performance;

        return Card(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(label: 'FPS', value: '${snapshot.currentFps}'),
                    _MetricChip(
                      label: 'Frame',
                      value: '${snapshot.frameNumber}',
                    ),
                    _MetricChip(
                      label: 'Update',
                      value: '${snapshot.lastUpdateMs.toStringAsFixed(1)} ms',
                    ),
                    _MetricChip(
                      label: 'Budget',
                      value:
                          '${snapshot.budgetRemainingMs.toStringAsFixed(1)} ms',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  snapshot.isOverBudget
                      ? 'Frame budget exceeded.'
                      : 'Performance within budget.',
                  style: TextStyle(
                    color: snapshot.isOverBudget
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'System timings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (snapshot.systemTimesMs.isEmpty)
                  const Text('No performance timing data available yet.')
                else
                  ...snapshot.systemTimesMs.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${entry.key}: ${entry.value.toStringAsFixed(2)} ms',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
