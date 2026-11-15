class EntityManageData {
  final String title;
  final String category;
  final String location;
  final String imageUrl;
  final String? organizer;

  final int? status;
  final int? views;
  final double? rating;
  final String? date;

  EntityManageData({
    required this.title,
    required this.category,
    required this.location,
    required this.imageUrl,
    this.organizer,
    this.status,
    this.views,
    this.rating,
    this.date,
  });
}
