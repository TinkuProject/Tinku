class HomeDashboardModel {
  final String mode;
  final PartnerHomeSummary? partner;
  final WarehouseHomeSummary? warehouse;
  final AdminHomeSummary? admin;

  const HomeDashboardModel({
    required this.mode,
    this.partner,
    this.warehouse,
    this.admin,
  });

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) {
    return HomeDashboardModel(
      mode: json['mode']?.toString() ?? 'partner',
      partner: json['partner'] is Map
          ? PartnerHomeSummary.fromJson(
              Map<String, dynamic>.from(json['partner'] as Map),
            )
          : null,
      warehouse: json['warehouse'] is Map
          ? WarehouseHomeSummary.fromJson(
              Map<String, dynamic>.from(json['warehouse'] as Map),
            )
          : null,
      admin: json['admin'] is Map
          ? AdminHomeSummary.fromJson(
              Map<String, dynamic>.from(json['admin'] as Map),
            )
          : null,
    );
  }
}

class PartnerHomeSummary {
  final int totalSales;
  final int activeSales;
  final int deliveredSales;
  final int activePublications;
  final int soldOutPublications;
  final int pendingTasks;

  const PartnerHomeSummary({
    required this.totalSales,
    required this.activeSales,
    required this.deliveredSales,
    required this.activePublications,
    required this.soldOutPublications,
    required this.pendingTasks,
  });

  factory PartnerHomeSummary.fromJson(Map<String, dynamic> json) {
    return PartnerHomeSummary(
      totalSales: _int(json['total_sales']),
      activeSales: _int(json['active_sales']),
      deliveredSales: _int(json['delivered_sales']),
      activePublications: _int(json['active_publications']),
      soldOutPublications: _int(json['sold_out_publications']),
      pendingTasks: _int(json['pending_tasks']),
    );
  }
}

class WarehouseHomeSummary {
  final int owned;
  final int pendingReceptions;
  final int incomingShipments;
  final int pendingDeliveries;

  const WarehouseHomeSummary({
    required this.owned,
    required this.pendingReceptions,
    required this.incomingShipments,
    required this.pendingDeliveries,
  });

  factory WarehouseHomeSummary.fromJson(Map<String, dynamic> json) {
    return WarehouseHomeSummary(
      owned: _int(json['owned']),
      pendingReceptions: _int(json['pending_receptions']),
      incomingShipments: _int(json['incoming_shipments']),
      pendingDeliveries: _int(json['pending_deliveries']),
    );
  }
}

class AdminHomeSummary {
  final int businesses;
  final int events;
  final int warehouses;
  final int claims;
  final int total;

  const AdminHomeSummary({
    required this.businesses,
    required this.events,
    required this.warehouses,
    required this.claims,
    required this.total,
  });

  factory AdminHomeSummary.fromJson(Map<String, dynamic> json) {
    return AdminHomeSummary(
      businesses: _int(json['businesses']),
      events: _int(json['events']),
      warehouses: _int(json['warehouses']),
      claims: _int(json['claims']),
      total: _int(json['total']),
    );
  }
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
