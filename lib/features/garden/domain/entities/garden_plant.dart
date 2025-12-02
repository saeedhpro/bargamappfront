class GardenPlant {
  final int id;
  final String plantName;
  final String nickname;
  final String? imageUrl;
  final Map<String, dynamic> details;

  GardenPlant({
    required this.id,
    required this.plantName,
    required this.nickname,
    this.imageUrl,
    required this.details,
  });

  factory GardenPlant.fromJson(Map<String, dynamic> json) {
    return GardenPlant(
      id: json['id'],
      plantName: json['plant_name'] ?? '',
      nickname: json['nickname'] ?? '',
      imageUrl: json['image_path'],
      details: json['details'] ?? {},
    );
  }
}
