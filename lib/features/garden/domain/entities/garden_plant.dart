class GardenPlant {
  final int id;
  final String plantName;
  final String nickname;
  final String? imagePath;
  final String? diseases;
  final String? pestControl;
  final Map<String, dynamic> details;

  GardenPlant({
    required this.id,
    required this.plantName,
    required this.nickname,
    this.imagePath,
    this.diseases,
    this.pestControl,
    required this.details,
  });

  factory GardenPlant.fromJson(Map<String, dynamic> json) {
    return GardenPlant(
      id: json['id'],
      plantName: json['plant_name'] ?? '',
      nickname: json['nickname'] ?? '',
      imagePath: json['image_path'],
      diseases: json['diseases'],
      pestControl: json['pest_control'],
      details: json['details'] ?? {},
    );
  }
}
