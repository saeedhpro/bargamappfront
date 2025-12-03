class GardenPlant {
  final int id;
  final String plantName;
  final String nickname;
  final String? imagePath;
  final Map<String, dynamic> details;

  GardenPlant({
    required this.id,
    required this.plantName,
    required this.nickname,
    this.imagePath,
    required this.details,
  });

  factory GardenPlant.fromJson(Map<String, dynamic> json) {
    return GardenPlant(
      id: json['id'],
      plantName: json['plant_name'] ?? '',
      nickname: json['nickname'] ?? '',
      imagePath: json['image_path'],
      details: json['details'] ?? {},
    );
  }
}
