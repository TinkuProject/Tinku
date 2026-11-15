// ignore_for_file: constant_identifier_names

// =========================
// USERS
// =========================
enum UserRole { user, partner, admin, master }
UserRole userRoleFromString(String v) =>
    UserRole.values.firstWhere((e) => e.name == v, orElse: () => UserRole.user);
String userRoleToString(UserRole v) => v.name;

enum UserStatus { active, inactive, suspended, deleted }
UserStatus userStatusFromString(String v) =>
    UserStatus.values.firstWhere((e) => e.name == v, orElse: () => UserStatus.inactive);
String userStatusToString(UserStatus v) => v.name;

// =========================
// TRANSACTIONS
// =========================
enum TransactionType {
  purchase,
  spend,
  reward,
  refund,
  cashout,
  admin_adjustment,
}
TransactionType transactionTypeFromString(String v) =>
    TransactionType.values.firstWhere((e) => e.name == v);
String transactionTypeToString(TransactionType v) => v.name;

enum TransactionStatus {
  pending,
  approved,
  rejected,
  failed,
  cancelled,
  reversed,
}
TransactionStatus transactionStatusFromString(String v) =>
    TransactionStatus.values.firstWhere((e) => e.name == v);
String transactionStatusToString(TransactionStatus v) => v.name;

// =========================
// PAYMENTS
// =========================
enum PaymentMethod { qr, gateway, cash_point }
PaymentMethod paymentMethodFromString(String v) =>
    PaymentMethod.values.firstWhere((e) => e.name == v);
String paymentMethodToString(PaymentMethod v) => v.name;

enum PaymentStatus {
  pending,
  approved,
  rejected,
  failed,
  cancelled,
  expired,
}
PaymentStatus paymentStatusFromString(String v) =>
    PaymentStatus.values.firstWhere((e) => e.name == v);
String paymentStatusToString(PaymentStatus v) => v.name;

// =========================
// SUBSCRIPTIONS
// =========================
enum SubscriptionStatus { active, paused, cancelled, expired }
SubscriptionStatus subscriptionStatusFromString(String v) =>
    SubscriptionStatus.values.firstWhere((e) => e.name == v);
String subscriptionStatusToString(SubscriptionStatus v) => v.name;

// =========================
// APPROVAL
// =========================
enum ApprovalStatus { pending, approved, rejected }
ApprovalStatus approvalStatusFromString(String v) =>
    ApprovalStatus.values.firstWhere((e) => e.name == v);
String approvalStatusToString(ApprovalStatus v) => v.name;

enum PaymentType {
  partner_upgrade,
  coin_purchase,
  subscription,
  product_publication,
  marketplace_order,
}
PaymentType paymentTypeFromString(String v) =>
    PaymentType.values.firstWhere((e) => e.name == v);
String paymentTypeToString(PaymentType v) => v.name;
// =========================
// BUSINESS
// =========================
enum BusinessType { business, service }
BusinessType businessTypeFromString(String v) =>
    BusinessType.values.firstWhere((e) => e.name == v);
String businessTypeToString(BusinessType v) => v.name;

enum BusinessStatus { active, inactive, suspended, pending }
BusinessStatus businessStatusFromString(String v) =>
    BusinessStatus.values.firstWhere((e) => e.name == v);
String businessStatusToString(BusinessStatus v) => v.name;

enum ProductStatus { active, inactive, out_of_stock }
ProductStatus productStatusFromString(String v) =>
    ProductStatus.values.firstWhere((e) => e.name == v);
String productStatusToString(ProductStatus v) => v.name;

enum EventStatus { pending, active, finished, cancelled }
EventStatus eventStatusFromString(String v) =>
    EventStatus.values.firstWhere((e) => e.name == v);
String eventStatusToString(EventStatus v) => v.name;

enum PromotionStatus { active, inactive, cancelled }
PromotionStatus promotionStatusFromString(String v) =>
    PromotionStatus.values.firstWhere((e) => e.name == v);
String promotionStatusToString(PromotionStatus v) => v.name;

// =========================
// INTERACTION
// =========================
enum VisitType { visited, favorited }
VisitType visitTypeFromString(String v) =>
    VisitType.values.firstWhere((e) => e.name == v);
String visitTypeToString(VisitType v) => v.name;

enum ReservationStatus { pending, confirmed, cancelled }
ReservationStatus reservationStatusFromString(String v) =>
    ReservationStatus.values.firstWhere((e) => e.name == v);
String reservationStatusToString(ReservationStatus v) => v.name;

enum EventTicketStatus { active, used, expired, cancelled }
EventTicketStatus eventTicketStatusFromString(String v) =>
    EventTicketStatus.values.firstWhere((e) => e.name == v);
String eventTicketStatusToString(EventTicketStatus v) => v.name;

enum ReviewStatus { visible, hidden, reported }
ReviewStatus reviewStatusFromString(String v) =>
    ReviewStatus.values.firstWhere((e) => e.name == v);
String reviewStatusToString(ReviewStatus v) => v.name;

enum ReviewEntityType { tourist_place, business, event, product }
ReviewEntityType reviewEntityTypeFromString(String v) =>
    ReviewEntityType.values.firstWhere((e) => e.name == v);
String reviewEntityTypeToString(ReviewEntityType v) => v.name;
// =========================
// MEDIA
// =========================
enum MediaType { image, video, file }
MediaType mediaTypeFromString(String v) =>
    MediaType.values.firstWhere((e) => e.name == v);
String mediaTypeToString(MediaType v) => v.name;

enum MediaEntityType {
  business,
  event,
  tourist_place,
  product,
  user,
  review,
  certification,
  category,
  payment,
  coin_package,
  subscription,
  discount,
  transport_line,
  charging_point,
  warehouse,
  product_publication
}
MediaEntityType mediaEntityTypeFromString(String v) =>
    MediaEntityType.values.firstWhere((e) => e.name == v);
String mediaEntityTypeToString(MediaEntityType v) => v.name;

// =========================
// ROUTES
// =========================
enum RouteDirection { outbound, return_ }
RouteDirection routeDirectionFromString(String v) {
  if (v == "return") return RouteDirection.return_;
  return RouteDirection.values.firstWhere((e) => e.name == v);
}
String routeDirectionToString(RouteDirection v) {
  if (v == RouteDirection.return_) return "return";
  return v.name;
}

// =========================
// GENERIC
// =========================
enum BasicStatus { active, inactive, archived }
BasicStatus basicStatusFromString(String v) =>
    BasicStatus.values.firstWhere((e) => e.name == v);
String basicStatusToString(BasicStatus v) => v.name;

// =========================
// GEO
// =========================
enum VisitEntity { tourist_place, business, event }
VisitEntity visitEntityFromString(String v) =>
    VisitEntity.values.firstWhere((e) => e.name == v);
String visitEntityToString(VisitEntity v) => v.name;

enum OpeningEntity { business, event, tourist_place, charging_point }
OpeningEntity openingEntityFromString(String v) =>
    OpeningEntity.values.firstWhere((e) => e.name == v);
String openingEntityToString(OpeningEntity v) => v.name;

MediaEntityType mediaEntityTypeFromVisitEntity(VisitEntity v) {
  switch (v) {
    case VisitEntity.business:
      return MediaEntityType.business;
    case VisitEntity.event:
      return MediaEntityType.event;
    case VisitEntity.tourist_place:
      return MediaEntityType.tourist_place;
  }
}
// =========================
// TIME
// =========================
enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}
WeekDay weekDayFromString(String v) =>
    WeekDay.values.firstWhere((e) => e.name == v);
String weekDayToString(WeekDay v) => v.name;

// =========================
// INFRASTRUCTURE
// =========================
enum ChargingPointStatus { active, inactive, maintenance }
ChargingPointStatus chargingPointStatusFromString(String v) =>
    ChargingPointStatus.values.firstWhere((e) => e.name == v);
String chargingPointStatusToString(ChargingPointStatus v) => v.name;

// =========================
// CATEGORY
// =========================
enum CategoryEntityType {
  business,
  event,
  tourist_place,
  product,
}
CategoryEntityType categoryEntityTypeFromString(String v) =>
    CategoryEntityType.values.firstWhere((e) => e.name == v);
String categoryEntityTypeToString(CategoryEntityType v) => v.name;

// =========================
// UPDATES
// =========================
enum UpdateEntityType { business, event, product, certification }
UpdateEntityType updateEntityTypeFromString(String v) =>
    UpdateEntityType.values.firstWhere((e) => e.name == v);
String updateEntityTypeToString(UpdateEntityType v) => v.name;
