import 'dart:convert';

import '../../models/nearby_item_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class NearbyService extends BaseService<NearbyItemModel> {
  NearbyService(AuthService authService) : super("nearby", authService);

  @override
  NearbyItemModel fromJson(Map<String, dynamic> json) {
    return NearbyItemModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(NearbyItemModel model) {
    return {
      'entity_id': model.entityId,
      'entity_type': model.entityType.name,
      'name': model.name,
      'latitude': model.latitude,
      'longitude': model.longitude,
      'distance': model.distance,
      'image_url': model.imageUrl,
    };
  }

  Future<List<NearbyItemModel>> getNearby({
    required double lat,
    required double lng,
    double radius = 5000,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radius.toString(),
      },
    );

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    return data
        .map<NearbyItemModel>(
          (e) => fromJson(Map<String, dynamic>.from(e)),
    )
        .toList();
  }
}
