import '../../domain/entities/plant.dart';

class PlantModel extends Plant {
  const PlantModel({
    required int id,
    required String imagePath,
    required String plantName,
    String? commonName,
    String? description,
    Map<String, dynamic> details = const {},
    required String createdAt,
  }) : super(
    // داده‌ها را مستقیماً به کلاس پدر (Plant) پاس می‌دهیم
    id: id,
    imagePath: imagePath,
    plantName: plantName,
    commonName: commonName,
    description: description,
    details: details,
    createdAt: createdAt,
  );

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'] as int,
      imagePath: json['image_path']?.toString() ?? '',
      plantName: json['plant_name']?.toString() ?? 'نامشخص',
      commonName: json['common_name']?.toString(),
      description: json['description']?.toString(),
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'])
          : {},
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  /// چون از Plant ارث‌بری کرده‌ایم، خود این کلاس هم نوعی Plant است.
  /// اما اگر نیاز دارید تبدیل صریح انجام دهید تا از شر متدهای اضافه مدل خلاص شوید:
  Plant toEntity() {
    return Plant(
      id: id,
      imagePath: imagePath,
      plantName: plantName,
      commonName: commonName,
      description: description,
      details: details,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'plant_name': plantName,
      'common_name': commonName,
      'description': description,
      'details': details,
      'created_at': createdAt,
    };
  }
}
