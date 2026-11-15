part of '../../../views/transport/public_transport_routes_page.dart';

class _LineSelectorSheet extends StatelessWidget {
  const _LineSelectorSheet({
    required this.controller,
    required this.scrollController,
    required this.onToggleLine,
    required this.onClose,
    required this.onShowMap,
  });

  final PublicTransportRoutesController controller;
  final ScrollController scrollController;
  final Future<void> Function(TransportLineModel line) onToggleLine;
  final VoidCallback onClose;
  final VoidCallback onShowMap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _LineSelectorPanel(
        controller: controller,
        scrollController: scrollController,
        onToggleLine: onToggleLine,
        onClose: onClose,
        onShowMap: onShowMap,
      ),
    );
  }
}

class _LineSelectorPanel extends StatelessWidget {
  const _LineSelectorPanel({
    required this.controller,
    required this.onToggleLine,
    required this.onShowMap,
    this.scrollController,
    this.onClose,
  });

  final PublicTransportRoutesController controller;
  final ScrollController? scrollController;
  final Future<void> Function(TransportLineModel line) onToggleLine;
  final VoidCallback? onClose;
  final VoidCallback onShowMap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, controller.queryChanges]),
      builder: (context, _) {
        final lines = controller.filteredLines;

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ver líneas',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: controller.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar línea o nombre',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surfaceSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${controller.selectedLineIds.length} seleccionadas',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: controller.selectedLineIds.isEmpty
                          ? null
                          : controller.clearSelection,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('Limpiar todo'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _LineList(
                  controller: controller,
                  lines: lines,
                  scrollController: scrollController,
                  onToggleLine: onToggleLine,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                        controller.selectedLineIds.isEmpty ? null : onShowMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver en mapa'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LineList extends StatelessWidget {
  const _LineList({
    required this.controller,
    required this.lines,
    required this.onToggleLine,
    this.scrollController,
  });

  final PublicTransportRoutesController controller;
  final List<TransportLineModel> lines;
  final Future<void> Function(TransportLineModel line) onToggleLine;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (controller.loadingLines) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.darkBlue),
      );
    }

    if (controller.linesError != null) {
      return _StateMessage(
        icon: Icons.cloud_off,
        title: 'No se pudieron cargar las líneas',
        actionLabel: 'Reintentar',
        onAction: controller.loadLines,
      );
    }

    if (controller.lines.isEmpty) {
      return const _StateMessage(
        icon: Icons.route_outlined,
        title: 'No hay líneas disponibles',
      );
    }

    if (lines.isEmpty) {
      return _StateMessage(
        icon: Icons.search_off,
        title: "No encontramos líneas relacionadas con '${controller.query}'",
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return _TransportLineTile(
          line: line,
          selected: controller.isSelected(line.id),
          loading: controller.isLoadingRoute(line.id),
          error: controller.routeError(line.id),
          summary: controller.routeSummary(line),
          onTap: () => onToggleLine(line),
          onRetry: () => controller.ensureRouteLoaded(line.id),
        );
      },
    );
  }
}

class _TransportLineTile extends StatelessWidget {
  const _TransportLineTile({
    required this.line,
    required this.selected,
    required this.loading,
    required this.error,
    required this.summary,
    required this.onTap,
    required this.onRetry,
  });

  final TransportLineModel line;
  final bool selected;
  final bool loading;
  final String? error;
  final String summary;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = TransportLineColorManager.getBaseColor(line.id);
    const textColor = AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              line.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: onRetry,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Checkbox(
                    value: selected,
                    activeColor: AppColors.darkBlue,
                    onChanged: (_) => onTap(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialBottomPanel extends StatelessWidget {
  const _InitialBottomPanel({
    required this.onOpenSelector,
  });

  final VoidCallback onOpenSelector;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: AppColors.pureWhite,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onOpenSelector,
        icon: const Icon(Icons.route),
        label: const Text('Ver líneas'),
      ),
    );
  }
}

class _SelectedLinesBottomPanel extends StatelessWidget {
  const _SelectedLinesBottomPanel({
    required this.controller,
    required this.onRemove,
    required this.onClear,
    required this.onOpenSelector,
    required this.onDetails,
  });

  final PublicTransportRoutesController controller;
  final void Function(int lineId) onRemove;
  final VoidCallback onClear;
  final VoidCallback onOpenSelector;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedLines;

    return Container(
      constraints: const BoxConstraints(maxHeight: 255),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 86),
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${selected.length} líneas seleccionadas',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onClear, child: const Text('Limpiar')),
            ],
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: selected.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final line = selected[index];
                final color = TransportLineColorManager.getBaseColor(line.id);
                return Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${line.name} - ${controller.routeSummary(line)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar línea',
                      onPressed: () => onRemove(line.id),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenSelector,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: AppColors.pureWhite,
                  ),
                  onPressed: onDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver detalles'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
