import '../core/just_debugger_controller.dart';

extension JustDebuggerSourceBinding on JustDebuggerController {
  void bindToSources({
    required EcsStatsProvider statsProvider,
    EcsComponentUsageProvider? componentUsageProvider,
    EcsSystemTimesProvider? systemTimesProvider,
    PerformanceStatsProvider? performanceStatsProvider,
    MemoryStatsProvider? memoryStatsProvider,
    MemoryCleanupAction? memoryCleanupAction,
    Duration interval = const Duration(milliseconds: 250),
    bool fireImmediately = true,
  }) {
    bind(
      statsProvider: statsProvider,
      componentUsageProvider: componentUsageProvider,
      systemTimesProvider: systemTimesProvider,
      performanceStatsProvider: performanceStatsProvider,
      memoryStatsProvider: memoryStatsProvider,
      memoryCleanupAction: memoryCleanupAction,
      interval: interval,
      fireImmediately: fireImmediately,
    );
  }
}
