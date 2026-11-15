import 'package:flutter/material.dart';

import '../filters/filter_chip.dart';
import '../filters/filter_bottom_sheet.dart';
import '../../../ui/enums/event_filters.dart';

class FilterBarEvents extends StatelessWidget {
  final EventFilterStatus status;
  final EventOrder order;
  final EventPriceFilter price;

  final ValueChanged<EventFilterStatus> onStatus;
  final ValueChanged<EventOrder> onOrder;
  final ValueChanged<EventPriceFilter> onPrice;

  final int? business;
  final Map<int, String>? businessItems;
  final ValueChanged<int>? onBusiness;

  const FilterBarEvents({
    super.key,
    required this.status,
    required this.order,
    required this.price,
    required this.onStatus,
    required this.onOrder,
    required this.onPrice,
    this.business,
    this.businessItems,
    this.onBusiness,
  });

  @override
  Widget build(BuildContext context) {
    const statusItems = {
      EventFilterStatus.all: "Todos",
      EventFilterStatus.upcoming: "Próximos",
      EventFilterStatus.past: "Pasados",
      EventFilterStatus.pending: "Pendientes",
      EventFilterStatus.approved: "Aprobados",
      EventFilterStatus.rejected: "Rechazados",
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChipWidget(
            icon: Icons.schedule,
            label: "Estado",
            value: statusItems[status]!,
            onTap: () => openFilter<EventFilterStatus>(
              context,
              "Estado",
              statusItems,
              status,
              onStatus,
            ),
          ),

          FilterChipWidget(
            icon: order == EventOrder.newest
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            label: "Orden",
            value: {
              EventOrder.newest: "Más recientes",
              EventOrder.oldest: "Más antiguos",
            }[order]!,
            onTap: () => openFilter<EventOrder>(
              context,
              "Ordenar por",
              const {
                EventOrder.newest: "Más recientes",
                EventOrder.oldest: "Más antiguos",
              },
              order,
              onOrder,
            ),
          ),

          FilterChipWidget(
            icon: Icons.tune,
            label: "Precio",
            value: {
              EventPriceFilter.all: "Todos",
              EventPriceFilter.free: "Gratis",
              EventPriceFilter.paid: "De pago",
            }[price]!,
            onTap: () => openFilter<EventPriceFilter>(
              context,
              "Precio",
              const {
                EventPriceFilter.all: "Todos",
                EventPriceFilter.free: "Gratis",
                EventPriceFilter.paid: "De pago",
              },
              price,
              onPrice,
            ),
          ),

          if (businessItems != null &&
              business != null &&
              onBusiness != null) ...[
            FilterChipWidget(
              icon: Icons.store,
              label: "Negocio",
              value: businessItems![business] ?? "Todos",
              onTap: () => openFilter<int>(
                context,
                "Negocio",
                businessItems!,
                business!,
                onBusiness!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
