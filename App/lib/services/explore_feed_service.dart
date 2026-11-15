import 'dart:convert';

import 'package:tinkuapp/config/config.dart';
import 'package:tinkuapp/models/business_model.dart';
import 'package:tinkuapp/models/category_model.dart';
import 'package:tinkuapp/models/event_model.dart';
import 'package:tinkuapp/models/tourist_place_model.dart';
import 'auth_service.dart';

class ExploreFeed {
  final List<BusinessModel> businesses;
  final List<CategoryModel> categories;
  final List<TouristPlaceModel> touristPlaces;
  final List<EventModel> events;
  final Map<int, String?> businessImages;
  final Map<int, String?> touristImages;
  final Map<int, String?> eventImages;
  final Map<int, double> businessRatings;
  final Map<int, double?> businessPrices;
  final bool hasMore;
  final int limit;
  final int offset;
  final int total;

  const ExploreFeed({
    required this.businesses,
    required this.categories,
    required this.touristPlaces,
    required this.events,
    required this.businessImages,
    required this.touristImages,
    required this.eventImages,
    required this.businessRatings,
    required this.businessPrices,
    required this.hasMore,
    required this.limit,
    required this.offset,
    required this.total,
  });
}

class ExploreFeedService {
  ExploreFeedService(this.authService);

  final AuthService authService;
  final String baseUrl = Config.baseUrl;

  Future<ExploreFeed> getFeed({
    int limit = 20,
    int offset = 0,
    String? query,
    String? type,
    int? categoryId,
  }) async {
    final client = authService.client;
    final uri = Uri.parse('$baseUrl/explore/feed').replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (categoryId != null) 'category_id': '$categoryId',
      },
    );
    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Formato inválido');
    }

    final pagination = data['pagination'] is Map
        ? Map<String, dynamic>.from(data['pagination'])
        : const <String, dynamic>{};

    return ExploreFeed(
      businesses: _list(data['businesses'], BusinessModel.fromJson),
      categories: _list(data['categories'], CategoryModel.fromJson),
      touristPlaces: _list(data['tourist_places'], TouristPlaceModel.fromJson),
      events: _list(data['events'], EventModel.fromJson),
      businessImages: _nullableStringMap(data['business_images']),
      touristImages: _nullableStringMap(data['tourist_images']),
      eventImages: _nullableStringMap(data['event_images']),
      businessRatings: _doubleMap(data['business_ratings']),
      businessPrices: _nullableDoubleMap(data['business_prices']),
      hasMore: pagination['has_more_any'] == true,
      limit: (pagination['limit'] as num?)?.toInt() ?? limit,
      offset: (pagination['offset'] as num?)?.toInt() ?? offset,
      total: pagination['total'] is Map
          ? ((pagination['total'] as Map)['all'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  List<T> _list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (value is! List) return [];

    return value
        .map<T>((item) => parser(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<int, String?> _nullableStringMap(dynamic value) {
    if (value is! Map<String, dynamic>) return {};

    return value.map(
      (key, item) => MapEntry(int.parse(key), item?.toString()),
    );
  }

  Map<int, double> _doubleMap(dynamic value) {
    if (value is! Map<String, dynamic>) return {};

    return value.map(
      (key, item) => MapEntry(int.parse(key), (item as num).toDouble()),
    );
  }

  Map<int, double?> _nullableDoubleMap(dynamic value) {
    if (value is! Map<String, dynamic>) return {};

    return value.map(
      (key, item) => MapEntry(
        int.parse(key),
        item == null ? null : (item as num).toDouble(),
      ),
    );
  }
}
