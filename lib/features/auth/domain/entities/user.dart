import 'user_subscription.dart';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String phoneNumber;
  final String? fullName;
  final UserSubscription? subscription;
  final bool hasSubscription;

  const User({
    required this.id,
    required this.phoneNumber,
    this.fullName,
    required this.hasSubscription,
    this.subscription,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final subscriptionData = json['subscription'];
    final parsedSubscription = subscriptionData != null
        ? UserSubscription.fromJson(subscriptionData)
        : null;

    final bool hasSub = parsedSubscription != null && parsedSubscription.isPremium;

    return User(
      id: json['id'].toString(),
      phoneNumber: json['phone'] ?? json['phone_number'] ?? 'نامشخص',
      fullName: json['full_name'],
      hasSubscription: hasSub,
      subscription: parsedSubscription,
    );
  }

  @override
  List<Object?> get props => [id, phoneNumber, fullName, subscription, hasSubscription];
}
