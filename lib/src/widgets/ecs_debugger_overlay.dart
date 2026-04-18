import 'package:flutter/material.dart';

import '../core/just_debugger_controller.dart';
import '../ecs/ecs_debugger_snapshot.dart';
import '../logs/debugger_log_entry.dart';

enum _OverlaySection { ecs, performance, memory, logs }

enum _LogFilter { all, info, warning, error }

extension on _OverlaySection {
  String get label => switch (this) {
    _OverlaySection.ecs => 'ECS',
    _OverlaySection.performance => 'Performance',
    _OverlaySection.memory => 'Memory',
    _OverlaySection.logs => 'Logs',
  };

  String get title => switch (this) {
    _OverlaySection.ecs => 'ECS Debugger',
    _OverlaySection.performance => 'Performance Debugger',
    _OverlaySection.memory => 'Memory Debugger',
    _OverlaySection.logs => 'Logs Console',
  };
}

extension on _LogFilter {
  String get label => switch (this) {
    _LogFilter.all => 'All',
    _LogFilter.info => 'Info',
    _LogFilter.warning => 'Warnings',
    _LogFilter.error => 'Errors',
  };
}

class EcsDebuggerOverlay extends StatefulWidget {
  const EcsDebuggerOverlay({
    super.key,
    required this.controller,
    this.alignment = Alignment.topRight,
    this.margin = const EdgeInsets.all(12),
  });

  final JustDebuggerController controller;
  final Alignment alignment;
  final EdgeInsets margin;

  @override
  State<EcsDebuggerOverlay> createState() => _EcsDebuggerOverlayState();
}

class _EcsDebuggerOverlayState extends State<EcsDebuggerOverlay> {
  _OverlaySection _selectedSection = _OverlaySection.ecs;
  _LogFilter _selectedLogFilter = _LogFilter.all;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (!widget.controller.overlayVisible) {
          return const SizedBox.shrink();
        }

        final primaryColor = Theme.of(context).primaryColor;
        final snapshot = widget.controller.snapshot;
        final health = widget.controller.health;
        final performance = widget.controller.performance;
        final memory = widget.controller.memory;
        final logs = widget.controller.logs;

        return Align(
          alignment: widget.alignment,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              margin: widget.margin,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSection.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final section in _OverlaySection.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _OverlayTabButton(
                                label: section.label,
                                summary: _summaryFor(
                                  section,
                                  snapshot: snapshot,
                                  performanceFps: performance.currentFps,
                                  componentCount: memory.componentCount,
                                  logCount: logs.length,
                                  usingFallback: memory.usingCacheFallback,
                                ),
                                selected: section == _selectedSection,
                                accentColor: primaryColor,
                                onTap: () {
                                  setState(() {
                                    _selectedSection = section;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: _buildSectionContent(
                            snapshot: snapshot,
                            health: health,
                            performanceFps: performance.currentFps,
                            frameNumber: performance.frameNumber,
                            lastUpdateMs: performance.lastUpdateMs,
                            budgetRemainingMs: performance.budgetRemainingMs,
                            isOverBudget: performance.isOverBudget,
                            componentCount: memory.componentCount,
                            memoryEntityCount: memory.entityCount,
                            counters: memory.counters,
                            usingFallback: memory.usingCacheFallback,
                            totalPhysicalMemoryBytes:
                                memory.totalPhysicalMemoryBytes,
                            freePhysicalMemoryBytes:
                                memory.freePhysicalMemoryBytes,
                            rssBytes: memory.rssBytes,
                            cleanupAvailable: memory.cleanupAvailable,
                            logs: logs,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _summaryFor(
    _OverlaySection section, {
    required EcsDebuggerSnapshot snapshot,
    required int performanceFps,
    required int componentCount,
    required int logCount,
    required bool usingFallback,
  }) {
    return switch (section) {
      _OverlaySection.ecs => '${snapshot.entityCount} ent',
      _OverlaySection.performance => '$performanceFps fps',
      _OverlaySection.memory =>
        usingFallback ? 'fallback' : '$componentCount cmp',
      _OverlaySection.logs => '$logCount events',
    };
  }

  Widget _buildSectionContent({
    required EcsDebuggerSnapshot snapshot,
    required DebuggerHealth health,
    required int performanceFps,
    required int frameNumber,
    required double lastUpdateMs,
    required double budgetRemainingMs,
    required bool isOverBudget,
    required int componentCount,
    required int memoryEntityCount,
    required Map<String, int> counters,
    required bool usingFallback,
    required int totalPhysicalMemoryBytes,
    required int freePhysicalMemoryBytes,
    required int rssBytes,
    required bool cleanupAvailable,
    required List<DebuggerLogEntry> logs,
  }) {
    switch (_selectedSection) {
      case _OverlaySection.ecs:
        return Column(
          key: const ValueKey('ecs'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Entities', value: '${snapshot.entityCount}'),
                _StatChip(
                  label: 'Active',
                  value: '${snapshot.activeEntityCount}',
                ),
                _StatChip(label: 'Systems', value: '${snapshot.systemCount}'),
                _StatChip(
                  label: 'Archetypes',
                  value: '${snapshot.archetypeCount}',
                ),
              ],
            ),
            if (health.hasWarnings) ...[
              const SizedBox(height: 10),
              const Text(
                'Warnings',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              for (final message in health.messages.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $message'),
                ),
            ],
          ],
        );
      case _OverlaySection.performance:
        return Column(
          key: const ValueKey('performance'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'FPS', value: '$performanceFps'),
                _StatChip(label: 'Frame', value: '$frameNumber'),
                _StatChip(
                  label: 'Update',
                  value: '${lastUpdateMs.toStringAsFixed(1)}ms',
                ),
                _StatChip(
                  label: 'Budget',
                  value: isOverBudget
                      ? 'Over'
                      : '${budgetRemainingMs.toStringAsFixed(1)}ms',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOverBudget
                  ? 'Frame budget is currently being exceeded.'
                  : 'Frame timing is within budget.',
              style: TextStyle(
                color: isOverBudget ? Colors.orangeAccent : Colors.greenAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case _OverlaySection.memory:
        final hasSystemMemoryStats = totalPhysicalMemoryBytes > 0;
        final usedPhysicalMemoryBytes = hasSystemMemoryStats
            ? (totalPhysicalMemoryBytes - freePhysicalMemoryBytes).clamp(
                0,
                totalPhysicalMemoryBytes,
              )
            : 0;
        const softBudgetBytes = 512 * 1024 * 1024;
        final rssPressure = rssBytes <= 0
            ? 0.0
            : (rssBytes / softBudgetBytes).clamp(0.0, 1.0);
        final usageRatio = hasSystemMemoryStats
            ? (usedPhysicalMemoryBytes / totalPhysicalMemoryBytes).clamp(
                0.0,
                1.0,
              )
            : rssPressure;
        final appFootprintRatio = hasSystemMemoryStats
            ? (rssBytes / totalPhysicalMemoryBytes).clamp(0.0, 1.0)
            : rssPressure;
        final poolCount = counters['pools'] ?? 0;
        final arenaCount = counters['arenas'] ?? 0;
        final usageColor = usageRatio >= 0.85
            ? Colors.redAccent
            : usageRatio >= 0.65
            ? Colors.orangeAccent
            : Colors.lightGreenAccent;

        return Column(
          key: const ValueKey('memory'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Entities', value: '$memoryEntityCount'),
                _StatChip(label: 'Components', value: '$componentCount'),
                _StatChip(label: 'Counters', value: '${counters.length}'),
                _StatChip(
                  label: 'Cache',
                  value: usingFallback ? 'Fallback' : 'Primary',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              usingFallback
                  ? 'Using memory fallback cache.'
                  : 'Primary cache provider is active.',
              style: TextStyle(
                color: usingFallback ? Colors.orangeAccent : Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'RAM Availability',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            _TieredProgressBar(value: usageRatio, color: usageColor),
            const SizedBox(height: 6),
            Text(
              hasSystemMemoryStats
                  ? '${(usageRatio * 100).toStringAsFixed(0)}% system RAM used • '
                        '${_formatBytes(usedPhysicalMemoryBytes)} / ${_formatBytes(totalPhysicalMemoryBytes)}'
                  : rssBytes > 0
                  ? 'App memory pressure: ${_formatBytes(rssBytes)} used'
                  : 'RAM metrics are unavailable on this platform.',
              style: TextStyle(color: usageColor),
            ),
            const SizedBox(height: 10),
            const Text(
              'Engine + Game Footprint',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            _TieredProgressBar(
              value: appFootprintRatio,
              color: Theme.of(context).primaryColor,
              minHeight: 10,
            ),
            const SizedBox(height: 6),
            const Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ProgressLegendItem(
                  label: 'Safe',
                  color: Colors.lightGreenAccent,
                ),
                _ProgressLegendItem(
                  label: 'Warning',
                  color: Colors.orangeAccent,
                ),
                _ProgressLegendItem(label: 'Critical', color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasSystemMemoryStats
                  ? 'Current game + just_game_engine: ${_formatBytes(rssBytes)} live RSS • Optimization headroom keeps ${_formatBytes(freePhysicalMemoryBytes)} free'
                  : rssBytes > 0
                  ? 'Current game + just_game_engine: ${_formatBytes(rssBytes)} live RSS against a ${_formatBytes(softBudgetBytes)} soft budget'
                  : 'Current game memory footprint is unavailable on this platform.',
              style: const TextStyle(color: Colors.white70),
            ),
            if (poolCount > 0 || arenaCount > 0)
              Text(
                'Optimization headroom is backed by just_game_engine pooling: $poolCount pools • $arenaCount arenas',
                style: const TextStyle(color: Colors.white70),
              ),
            if (cleanupAvailable) ...[
              const SizedBox(height: 6),
              const Text(
                'Free up space using just_memory cleanup for pools, arenas, and caches.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ],
        );
      case _OverlaySection.logs:
        final infoCount = logs
            .where((entry) => entry.level == DebuggerLogLevel.info)
            .length;
        final warningCount = logs
            .where((entry) => entry.level == DebuggerLogLevel.warning)
            .length;
        final errorCount = logs
            .where((entry) => entry.level == DebuggerLogLevel.error)
            .length;
        final visibleLogs = logs.reversed
            .where(
              (entry) => switch (_selectedLogFilter) {
                _LogFilter.all => true,
                _LogFilter.info => entry.level == DebuggerLogLevel.info,
                _LogFilter.warning => entry.level == DebuggerLogLevel.warning,
                _LogFilter.error => entry.level == DebuggerLogLevel.error,
              },
            )
            .take(6)
            .toList(growable: false);

        return Column(
          key: const ValueKey('logs'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Total', value: '${logs.length}'),
                _StatChip(label: 'Info', value: '$infoCount'),
                _StatChip(label: 'Warnings', value: '$warningCount'),
                _StatChip(label: 'Errors', value: '$errorCount'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final filter in _LogFilter.values)
                        _LogFilterChip(
                          label: filter.label,
                          selected: filter == _selectedLogFilter,
                          color: switch (filter) {
                            _LogFilter.all => Colors.white70,
                            _LogFilter.info => Colors.blueAccent,
                            _LogFilter.warning => Colors.orangeAccent,
                            _LogFilter.error => Colors.redAccent,
                          },
                          onTap: () {
                            setState(() {
                              _selectedLogFilter = filter;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                if (logs.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      widget.controller.clearLogs();
                      setState(() {
                        _selectedLogFilter = _LogFilter.all;
                      });
                    },
                    child: const Text('Clear Logs'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (visibleLogs.isEmpty)
              const Text(
                'No logs match the selected filter.',
                style: TextStyle(color: Colors.white70),
              )
            else
              for (final entry in visibleLogs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _OverlayLogTile(entry: entry),
                ),
          ],
        );
    }
  }
}

class _OverlayTabButton extends StatelessWidget {
  const _OverlayTabButton({
    required this.label,
    required this.summary,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final String summary;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? accentColor
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? accentColor : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              summary,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _TieredProgressBar extends StatelessWidget {
  const _TieredProgressBar({
    required this.value,
    required this.color,
    this.minHeight = 8,
  });

  final double value;
  final Color color;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: minHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 60,
                  child: Container(
                    color: Colors.lightGreenAccent.withValues(alpha: 0.16),
                  ),
                ),
                Expanded(
                  flex: 25,
                  child: Container(
                    color: Colors.orangeAccent.withValues(alpha: 0.16),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Container(
                    color: Colors.redAccent.withValues(alpha: 0.16),
                  ),
                ),
              ],
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedValue,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.75), color],
                  ),
                ),
              ),
            ),
            if (clampedValue > 0)
              Align(
                alignment: Alignment(clampedValue * 2 - 1, 0),
                child: Container(
                  width: 2,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLegendItem extends StatelessWidget {
  const _ProgressLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

class _LogFilterChip extends StatelessWidget {
  const _LogFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? color : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _OverlayLogTile extends StatelessWidget {
  const _OverlayLogTile({required this.entry});

  final DebuggerLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.level) {
      DebuggerLogLevel.info => Colors.blueAccent,
      DebuggerLogLevel.warning => Colors.orangeAccent,
      DebuggerLogLevel.error => Colors.redAccent,
    };

    final icon = switch (entry.level) {
      DebuggerLogLevel.info => Icons.info_outline,
      DebuggerLogLevel.warning => Icons.warning_amber_rounded,
      DebuggerLogLevel.error => Icons.error_outline,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.category.toUpperCase()} • ${entry.timeLabel}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
