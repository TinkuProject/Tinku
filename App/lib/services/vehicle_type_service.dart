import '../../models/vehicle_type_model.dart';
import 'base_service.dart';
import 'auth_service.dart';

class VehicleTypeService extends BaseService<VehicleTypeModel> {
  VehicleTypeService(AuthService authService)
      : super("vehicle-types", authService);

  @override
  VehicleTypeModel fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(VehicleTypeModel model) {
    return model.toJson();
  }
}