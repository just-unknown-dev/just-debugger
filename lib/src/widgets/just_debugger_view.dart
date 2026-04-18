import 'package:flutter/material.dart';

import '../core/just_debugger_controller.dart';
import 'ecs_debugger_overlay.dart';
import 'ecs_debugger_panel.dart';

class JustDebuggerView extends StatelessWidget {
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

  final JustDebuggerController controller;
  final Widget child;
  final bool showOverlay;
  final bool showInspectorPanel;
  final Alignment inspectorAlignment;
  final double inspectorWidth;
  final double inspectorHeight;
  final Widget? inspectorChild;
  final Alignment overlayAlignment;
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
          EcsDebuggerOverlay(
            controller: controller,
            alignment: overlayAlignment,
            margin: overlayMargin,
          ),
      ],
    );
  }
}
