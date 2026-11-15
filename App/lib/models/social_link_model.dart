class SocialLinkModel {
  final int id;
  final int businessId;
  final String platform;
  final String url;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SocialLinkModel({
    required this.id,
    required this.businessId,
    required this.platform,
    required this.url,
    this.createdAt,
    this.updatedAt,
  });

  factory SocialLinkModel.fromJson(Map<String, dynamic> json) {
    return SocialLinkModel(
      id: json['id'],
      businessId: json['business_id'],
      platform: json['platform'],
      url: json['url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'platform': platform,
      'url': url,
    };
  }
}