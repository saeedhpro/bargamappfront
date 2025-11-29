import 'package:equatable/equatable.dart';

class Plant extends Equatable {
  final int id;
  final String imagePath;
  final String plantName; // نام علمی
  final String? commonName; // نام فارسی
  final String? description;
  final Map<String, dynamic> details;
  final String createdAt;

  const Plant({
    required this.id,
    required this.imagePath,
    required this.plantName,
    this.commonName,
    this.description,
    this.details = const {},
    required this.createdAt,
  });

  /// هلپرها (Helpers) برای استخراج داده‌های تمیز از داخل Map details
  /// این کار باعث می‌شود کد UI شما تمیز بماند و درگیر parsing جیسون نشود.

  int get wateringInterval {
    // تلاش برای خواندن عدد، اگر نبود پیش‌فرض ۷ روز
    if (details.containsKey('watering_interval')) {
      return int.tryParse(details['watering_interval'].toString()) ?? 7;
    }
    return 7;
  }

  String get lightRequirement {
    return details['light_requirement']?.toString() ?? 'medium';
  }

  // چون فیلد isFavorite در دیتابیس نیست، فعلاً پیش‌فرض false می‌گذاریم
  // یا اگر در آینده به details اضافه شد، از آنجا می‌خوانیم
  bool get isFavorite => false;

  /// متد کپی برای تغییر وضعیت (State Management)
  Plant copyWith({
    int? id,
    String? imagePath,
    String? plantName,
    String? commonName,
    String? description,
    Map<String, dynamic>? details,
    String? createdAt,
  }) {
    return Plant(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      plantName: plantName ?? this.plantName,
      commonName: commonName ?? this.commonName,
      description: description ?? this.description,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    imagePath,
    plantName,
    commonName,
    description,
    details,
    createdAt,
  ];
}
