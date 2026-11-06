import 'package:flutter/material.dart';

import '../controller/controller.dart';
import 'debugger_overlay.dart';
import 'ecs_debugger_panel.dart';

/// Shows [child] (the game) with the debugger over it: the
/// [DebuggerOverlay] and, when asked for, an inspector panel.
class JustDebuggerView extends StatelessWidget {
  /// A view of [child] with [controller]'s debugger over it.
  const JustDebuggerView({
    super.key,
    required this.controller,
    required this.child,
    this.showOverlay = true,
    this.showInspectorPanel = false,
    this.inspectorAlignment = Alignment.bottomLeft,
    this.inspectorWidth = 360,
    this.inspectorHeight = 320,
    this.inspectorChild,
    this.overlayAlignment = Alignment.topRight,
    this.overlayMargin = const EdgeInsets.all(12),
  });

  /// What the debugger shows.
  final JustDebuggerController controller;

  /// The game, or whatever is being debugged; it fills the view.
  final Widget child;

  /// Whether the [DebuggerOverlay] is shown.
  final bool showOverlay;

  /// Whether the inspector panel is shown.
  final bool showInspectorPanel;

  /// Where the inspector panel sits.
  final Alignment inspectorAlignment;

  /// The inspector panel's width.
  final double inspectorWidth;

  /// The inspector panel's height.
  final double inspectorHeight;

  /// What the inspector panel holds; an [EcsDebuggerPanel] when null.
  final Widget? inspectorChild;

  /// Where the overlay sits.
  final Alignment overlayAlignment;

  /// The space around the overlay.
  final EdgeInsets overlayMargin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (showInspectorPanel)
          Align(
            alignment: inspectorAlignment,
            child: Container(
              width: inspectorWidth,
              height: inspectorHeight,
              margin: const EdgeInsets.all(12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child:
                    inspectorChild ?? EcsDebuggerPanel(controller: controller),
              ),
            ),
          ),
        if (showOverlay)
          DebuggerOverlay(
            controller: controller,
            alignment: overlayAlignment,
            margin: overlayMargin,
          ),
      ],
    );
  }
}
