import 'package:equatable/equatable.dart';

class Plant extends Equatable {
  final String id;
  final String name;
  final String scientificName;
  final String? imageUrl;
  final int wateringInterval; // days
  final int fertilizerInterval; // days
  final String lightRequirement;
  final bool isFavorite;

  const Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    this.imageUrl,
    required this.wateringInterval,
    required this.fertilizerInterval,
    required this.lightRequirement,
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    scientificName,
    imageUrl,
    wateringInterval,
    fertilizerInterval,
    lightRequirement,
    isFavorite,
  ];
}
