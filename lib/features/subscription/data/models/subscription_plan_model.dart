class SubscriptionPlanModel {
  final int id;
  final String title;
  final String? description;
  final int price;
  final int durationDays;
  final int dailyPlantIdLimit;
  final int dailyDiseaseIdLimit;

  SubscriptionPlanModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.durationDays,
    required this.dailyPlantIdLimit,
    required this.dailyDiseaseIdLimit,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'],
      durationDays: json['duration_days'],
      dailyPlantIdLimit: json['daily_plant_id_limit'],
      dailyDiseaseIdLimit: json['daily_disease_id_limit'],
    );
  }

  String get formattedPrice {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
