import '../core/enums.dart';
import '../helpers/media_helper.dart';
import '../models/user_model.dart';

extension UserExtension on UserModel {
  String get displayName {
    final name = [firstName, lastName]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .join(' ')
        .trim();

    return name.isNotEmpty ? name : username;
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isPartner => role == UserRole.partner;
  bool get isMaster => role == UserRole.master;
  bool get isRegularUser => role == UserRole.user;

  String? get photoUrl => MediaHelper.getPrimaryUrl(media ?? []);
}