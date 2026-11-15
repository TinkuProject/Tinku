class SystemConfigModel {
  final String key;
  final dynamic value;
  final String? description;

  SystemConfigModel({
    required this.key,
    required this.value,
    this.description,
  });

  factory SystemConfigModel.fromJson(Map<String, dynamic> json) {
    return SystemConfigModel(
      key: json['key'],
      value: json['value'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
    };
  }
}