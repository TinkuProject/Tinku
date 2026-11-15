import '../models/user_subscription_model.dart';

String getSubscriptionLabel(UserSubscriptionModel? sub) {
  if (sub == null) return "Gratis";

  if (sub.endDate != null && sub.endDate!.isAfter(DateTime.now())) {
    return "Activo";
  }

  return "Expirado";
}