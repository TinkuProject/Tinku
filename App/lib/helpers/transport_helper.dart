import '../../core/enums.dart';
import '../../models/transport_route_model.dart';

class TransportHelper {
  static Map<RouteDirection, List<TransportRouteModel>> splitAndSort(
      List<TransportRouteModel> routes,
      ) {
    final outbound = routes
        .where((r) => r.direction == RouteDirection.outbound)
        .toList()
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    final back = routes
        .where((r) => r.direction == RouteDirection.return_)
        .toList()
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    return {
      RouteDirection.outbound: outbound,
      RouteDirection.return_: back,
    };
  }
}