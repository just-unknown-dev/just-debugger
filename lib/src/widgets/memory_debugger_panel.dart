import 'package:flutter/material.dart';

import '../core/just_debugger_controller.dart';

class MemoryDebuggerPanel extends StatelessWidget {
  const MemoryDebuggerPanel({super.key, required this.controller});

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
        const softBudgetBytes = 512 * 1024 * 1024;
        final rssPressure = snapshot.rssBytes <= 0
            ? 0.0
            : (snapshot.rssBytes / softBudgetBytes).clamp(0.0, 1.0);

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
                        value: _formatBytes(snapshot.rssBytes),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  snapshot.usingCacheFallback
                      ? 'CacheManager is running in memory fallback mode.'
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
                    '${_formatBytes(snapshot.freePhysicalMemoryBytes)} available '
                    'of ${_formatBytes(snapshot.totalPhysicalMemoryBytes)}',
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
                    'against a ${_formatBytes(softBudgetBytes)} soft budget.',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else
                  const Text(
                    'System RAM metrics are not available on this platform yet.',
                  ),
                const SizedBox(height: 12),
                if (controller.canCleanupMemory)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await controller.requestMemoryCleanup();
                    },
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Free Up RAM'),
                  ),
                if (controller.canCleanupMemory) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Uses just_memory to release tracked pools, arenas, and temporary caches.',
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

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final precision = unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
}
