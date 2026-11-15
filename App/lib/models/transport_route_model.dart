import '../core/enums.dart';
import '../utils/parsers/parse_utils.dart';

class TransportRouteModel {
  final int id;
  final int transportLineId;
  final RouteDirection direction;
  final int stopOrder;

  final double latitude;
  final double longitude;

  TransportRouteModel({
    required this.id,
    required this.transportLineId,
    required this.direction,
    required this.stopOrder,
    required this.latitude,
    required this.longitude,
  });

  factory TransportRouteModel.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;

    final location = json['location'];

    if (location != null) {
      lat = parseDouble(location['latitude']);
      lng = parseDouble(location['longitude']);
    }

    return TransportRouteModel(
      id: json['id'],
      transportLineId: json['transport_line_id'],
      direction: routeDirectionFromString(json['direction']),
      stopOrder: json['stop_order'],
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transport_line_id': transportLineId,
      'direction': routeDirectionToString(direction),
      'stop_order': stopOrder,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
    };
  }
}