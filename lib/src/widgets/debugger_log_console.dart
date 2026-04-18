import 'package:flutter/material.dart';

import '../core/just_debugger_controller.dart';
import '../logs/debugger_log_entry.dart';

enum _LogConsoleFilter { all, info, warning, error }

extension on _LogConsoleFilter {
  String get label => switch (this) {
    _LogConsoleFilter.all => 'All',
    _LogConsoleFilter.info => 'Info',
    _LogConsoleFilter.warning => 'Warnings',
    _LogConsoleFilter.error => 'Errors',
  };
}

class DebuggerLogConsole extends StatefulWidget {
  const DebuggerLogConsole({super.key, required this.controller});

  final JustDebuggerController controller;

  @override
  State<DebuggerLogConsole> createState() => _DebuggerLogConsoleState();
}

class _DebuggerLogConsoleState extends State<DebuggerLogConsole> {
  _LogConsoleFilter _selectedFilter = _LogConsoleFilter.all;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final logs = widget.controller.logs.reversed.toList();
        final infoCount = logs
            .where((entry) => entry.level == DebuggerLogLevel.info)
            .length;
        final warningCount = logs
            .where((entry) => entry.level == DebuggerLogLevel.warning)
            .length;
        final errorCount = logs
            .where((entry) => entry.level == DebuggerLogLevel.error)
            .length;
        final filteredLogs = logs
            .where((entry) {
              return switch (_selectedFilter) {
                _LogConsoleFilter.all => true,
                _LogConsoleFilter.info => entry.level == DebuggerLogLevel.info,
                _LogConsoleFilter.warning =>
                  entry.level == DebuggerLogLevel.warning,
                _LogConsoleFilter.error =>
                  entry.level == DebuggerLogLevel.error,
              };
            })
            .toList(growable: false);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Logs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        widget.controller.clearLogs();
                        setState(() {
                          _selectedFilter = _LogConsoleFilter.all;
                        });
                      },
                      child: const Text('Clear Logs'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(label: 'Total', value: '${logs.length}'),
                    _SummaryChip(label: 'Info', value: '$infoCount'),
                    _SummaryChip(label: 'Warnings', value: '$warningCount'),
                    _SummaryChip(label: 'Errors', value: '$errorCount'),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final filter in _LogConsoleFilter.values)
                      _ConsoleFilterChip(
                        label: filter.label,
                        selected: filter == _selectedFilter,
                        color: switch (filter) {
                          _LogConsoleFilter.all => Colors.blueGrey,
                          _LogConsoleFilter.info => Colors.blueAccent,
                          _LogConsoleFilter.warning => Colors.orangeAccent,
                          _LogConsoleFilter.error => Colors.redAccent,
                        },
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (filteredLogs.isEmpty)
                  const Text('No debugger logs match the current filter.')
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredLogs.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return _LogTile(entry: log);
                      },
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _ConsoleFilterChip extends StatelessWidget {
  const _ConsoleFilterChip({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? color
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.category.toUpperCase()} • ${entry.timeLabel}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(entry.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
