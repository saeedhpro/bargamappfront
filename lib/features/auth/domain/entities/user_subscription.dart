class UserSubscription {
  final String planTitle;
  final bool isPremium;
  final String? expiresAt;
  final int frozenDailyPlantIdLimit;
  final int frozenDiseaseIdLimit;

  UserSubscription({
    required this.planTitle,
    required this.isPremium,
    this.expiresAt,
    required this.frozenDailyPlantIdLimit,
    required this.frozenDiseaseIdLimit,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      planTitle: json['plan_title'] ?? 'طرح رایگان',
      isPremium: json['is_premium'] ?? false,
      expiresAt: json['expires_at'],
      frozenDailyPlantIdLimit: json['daily_plant_limit'] ?? 0,
      frozenDiseaseIdLimit: json['daily_disease_limit'] ?? 0,
    );
  }
}
