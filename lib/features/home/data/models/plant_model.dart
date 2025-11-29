import '../../domain/entities/plant.dart';

class PlantModel extends Plant {
  const PlantModel({
    required super.id,
    required super.name,
    required super.scientificName,
    super.imageUrl,
    required super.wateringInterval,
    required super.fertilizerInterval,
    required super.lightRequirement,
    super.isFavorite,
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      scientificName: json['scientific_name'] ?? '',
      imageUrl: json['image_url'],
      wateringInterval: json['watering_interval'] ?? 7,
      fertilizerInterval: json['fertilizer_interval'] ?? 30,
      lightRequirement: json['light_requirement'] ?? 'medium',
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'image_url': imageUrl,
      'watering_interval': wateringInterval,
      'fertilizer_interval': fertilizerInterval,
      'light_requirement': lightRequirement,
      'is_favorite': isFavorite,
    };
  }
}
