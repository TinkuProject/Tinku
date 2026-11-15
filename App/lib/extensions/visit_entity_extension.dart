import '../core/enums.dart';

extension VisitEntityX on VisitEntity {
  String get value {
    switch (this) {
      case VisitEntity.tourist_place:
        return 'tourist_place';
      case VisitEntity.business:
        return 'business';
      case VisitEntity.event:
        return 'event';
    }
  }

  String get label {
    switch (this) {
      case VisitEntity.tourist_place:
        return 'Turismo';
      case VisitEntity.business:
        return 'Negocio';
      case VisitEntity.event:
        return 'Evento';
    }
  }
}

VisitEntity visitEntityFromString(String v) {
  switch (v) {
    case 'tourist_place':
      return VisitEntity.tourist_place;
    case 'business':
      return VisitEntity.business;
    case 'event':
      return VisitEntity.event;
    default:
      throw Exception('Invalid VisitEntity: $v');
  }
}
