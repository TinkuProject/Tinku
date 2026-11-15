import '../core/enums.dart';

String getRoleLabel(UserRole? role) {
  switch (role) {
    case UserRole.master:
      return 'Master';
    case UserRole.admin:
      return 'Admin';
    case UserRole.partner:
      return 'Socio';
    case UserRole.user:
      return 'Usuario';
    default:
      return 'Invitado';
  }
}