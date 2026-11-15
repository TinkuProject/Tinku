class LineStopDetailModel {
  final int stopId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String direction;
  final int order;
  final String stopType;

  LineStopDetailModel({
    required this.stopId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.direction,
    required this.order,
    required this.stopType,
  });

  factory LineStopDetailModel.fromJson(Map<String, dynamic> json) {
    return LineStopDetailModel(
      stopId: json['stopId'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      direction: json['direction'] ?? '',
      order: json['order'] ?? 0,
      stopType: json['stopType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'stopId': stopId,
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
    'direction': direction,
    'order': order,
    'stopType': stopType,
  };
}
