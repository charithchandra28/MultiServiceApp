class ServiceModel {
  final String id;
  final String name;
  final String imageKey;

  ServiceModel({required this.id, required this.name, required this.imageKey});

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      imageKey: json['imageKey'],
    );
  }

  /// Converts a ServiceModel instance to a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageKey': imageKey,
    };
  }

  /// Converts a list of ServiceModel objects to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> toMapList(List<ServiceModel> services) {
    return services.map((service) => service.toJson()).toList();
  }

}
