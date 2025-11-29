import 'package:equatable/equatable.dart';

class Tool extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool isActive;

  const Tool({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, title, description, iconName, isActive];
}
