class ShopModel {
  final String id;
  final String name;
  final String description;
  final String servicetype;
  final String imageUrl;

  ShopModel({
    required this.id,
    required this.name,
    required this.description,
    required this.servicetype,
    required this.imageUrl,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      servicetype: json['servicetype'],
      imageUrl: json['image_url'],
    );
  }
}
