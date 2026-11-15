import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../ui/themes/colors.dart';
import '../../utils/accessibility/color_contrast.dart';

enum FlowTimelineStepState { completed, current, upcoming, error }

class FlowTimelineStep {
  final String label;
  final String? description;
  final DateTime? occurredAt;
  final FlowTimelineStepState state;
  final IconData? icon;

  const FlowTimelineStep({
    required this.label,
    required this.state,
    this.description,
    this.occurredAt,
    this.icon,
  });
}

class FlowTimeline extends StatelessWidget {
  final List<FlowTimelineStep> steps;
  final String? title;
  final bool compact;

  const FlowTimeline({
    super.key,
    required this.steps,
    this.title,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: title ?? 'Progreso del proceso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
          ],
          for (var index = 0; index < steps.length; index++)
            _TimelineStepRow(
              step: steps[index],
              index: index,
              total: steps.length,
              compact: compact,
              showConnector: index < steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class FlowTimelinePanel extends StatelessWidget {
  final List<FlowTimelineStep> steps;
  final String title;
  final bool initiallyExpanded;

  const FlowTimelinePanel({
    super.key,
    required this.steps,
    this.title = 'Seguimiento',
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final highlighted = steps.firstWhere(
      (step) => step.state == FlowTimelineStepState.current,
      orElse: () => steps.firstWhere(
        (step) => step.state == FlowTimelineStepState.error,
        orElse: () => steps.last,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          leading: const Icon(Icons.route_outlined, color: AppColors.darkBlue),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            highlighted.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          children: [FlowTimeline(steps: steps, compact: true)],
        ),
      ),
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.step,
    required this.index,
    required this.total,
    required this.compact,
    required this.showConnector,
  });

  final FlowTimelineStep step;
  final int index;
  final int total;
  final bool compact;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final colors = _StepColors.resolve(step.state);
    final icon = step.icon ?? _defaultIcon(step.state);
    final statusLabel = _stateLabel(step.state);
    final bottomPadding = showConnector ? (compact ? 10.0 : 14.0) : 0.0;

    return Semantics(
      container: true,
      label: 'Paso ${index + 1} de $total, ${step.label}, $statusLabel',
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (showConnector)
              Positioned(
                left: 13,
                top: 28,
                bottom: -bottomPadding,
                child: Container(
                  width: 2,
                  color: colors.connector,
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.foreground, width: 1.5),
                    ),
                    child: Icon(icon, size: 15, color: colors.foreground),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                            color: colors.text,
                            fontWeight:
                                step.state == FlowTimelineStepState.upcoming
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: colors.foreground,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!compact &&
                            step.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            step.description!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                        if (step.occurredAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(step.occurredAt!.toLocal()),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static IconData _defaultIcon(FlowTimelineStepState state) {
    return switch (state) {
      FlowTimelineStepState.completed => Icons.check_rounded,
      FlowTimelineStepState.current => Icons.more_horiz_rounded,
      FlowTimelineStepState.upcoming => Icons.circle_outlined,
      FlowTimelineStepState.error => Icons.close_rounded,
    };
  }

  static String _stateLabel(FlowTimelineStepState state) {
    return switch (state) {
      FlowTimelineStepState.completed => 'Completado',
      FlowTimelineStepState.current => 'Actual',
      FlowTimelineStepState.upcoming => 'Pendiente',
      FlowTimelineStepState.error => 'Interrumpido',
    };
  }
}

class _StepColors {
  final Color foreground;
  final Color background;
  final Color connector;
  final Color text;

  const _StepColors({
    required this.foreground,
    required this.background,
    required this.connector,
    required this.text,
  });

  factory _StepColors.resolve(FlowTimelineStepState state) {
    final source = switch (state) {
      FlowTimelineStepState.completed => AppColors.emerald,
      FlowTimelineStepState.current => AppColors.darkBlue,
      FlowTimelineStepState.upcoming => AppColors.textSecondary,
      FlowTimelineStepState.error => AppColors.error,
    };
    final background = Color.alphaBlend(
      source.withValues(alpha: 0.12),
      Colors.white,
    );
    final foreground = accessibleOnLight(source, background);

    return _StepColors(
      foreground: foreground,
      background: background,
      connector: state == FlowTimelineStepState.upcoming
          ? AppColors.border
          : foreground.withValues(alpha: 0.45),
      text: state == FlowTimelineStepState.upcoming
          ? AppColors.textSecondary
          : AppColors.textPrimary,
    );
  }
}
