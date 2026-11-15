class TouristPlaceTagModel {
  final int touristPlaceId;
  final int tagId;

  TouristPlaceTagModel({
    required this.touristPlaceId,
    required this.tagId,
  });

  factory TouristPlaceTagModel.fromJson(Map<String, dynamic> json) {
    return TouristPlaceTagModel(
      touristPlaceId: json['tourist_place_id'],
      tagId: json['tag_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tourist_place_id': touristPlaceId,
      'tag_id': tagId,
    };
  }
}