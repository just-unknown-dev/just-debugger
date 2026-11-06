import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/controller.dart';
import 'byte_format.dart';

/// A card with [controller]'s latest memory snapshot: counts, the cache's
/// state, the machine's RAM (or the app's footprint when that is unknown),
/// the published counters, and a Free Up RAM button when a cleanup can run.
class MemoryDebuggerPanel extends StatelessWidget {
  /// A panel for [controller].
  const MemoryDebuggerPanel({super.key, required this.controller});

  /// What the panel shows.
  final JustDebuggerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.memory;
        final theme = Theme.of(context);
        final primaryColor = theme.primaryColor;
        final availability = snapshot.availabilityRatio.clamp(0.0, 1.0);
        final rssPressure = snapshot.rssBytes <= 0
            ? 0.0
            : (snapshot.rssBytes / memorySoftBudgetBytes).clamp(0.0, 1.0);

        return Card(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Memory', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MemoryStat(
                      label: 'Components',
                      value: '${snapshot.componentCount}',
                    ),
                    _MemoryStat(
                      label: 'Entities',
                      value: '${snapshot.entityCount}',
                    ),
                    _MemoryStat(
                      label: 'Fallback',
                      value: snapshot.usingCacheFallback ? 'On' : 'Off',
                    ),
                    if (snapshot.rssBytes > 0)
                      _MemoryStat(
                        label: 'App RSS',
                        value: formatBytes(snapshot.rssBytes),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  snapshot.usingCacheFallback
                      ? 'The cache is running in memory fallback mode.'
                      : 'Primary cache backend is available.',
                  style: TextStyle(
                    color: snapshot.usingCacheFallback
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'RAM Availability',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (snapshot.hasSystemMemoryStats) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: availability,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(availability * 100).toStringAsFixed(0)}% free • '
                    '${formatBytes(snapshot.freePhysicalMemoryBytes)} available '
                    'of ${formatBytes(snapshot.totalPhysicalMemoryBytes)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else if (snapshot.rssBytes > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: rssPressure,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OS-wide free RAM is unavailable here, so this shows app memory pressure '
                    'against a ${formatBytes(memorySoftBudgetBytes)} soft budget.',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else
                  const Text(
                    'System RAM metrics are not available on this platform yet.',
                  ),
                const SizedBox(height: 12),
                if (controller.canCleanupMemory)
                  ElevatedButton.icon(
                    // Off while a cleanup runs, so one press runs one.
                    onPressed: controller.isCleaningMemory
                        ? null
                        : () => unawaited(controller.requestMemoryCleanup()),
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Free Up RAM'),
                  ),
                if (controller.canCleanupMemory) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Runs the attached cleanup action to release pools, '
                    'arenas and caches.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Counters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (snapshot.counters.isEmpty)
                  const Text('No memory counters have been published yet.')
                else
                  ...snapshot.counters.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${entry.key}: ${entry.value}'),
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

class _MemoryStat extends StatelessWidget {
  const _MemoryStat({required this.label, required this.value});

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
