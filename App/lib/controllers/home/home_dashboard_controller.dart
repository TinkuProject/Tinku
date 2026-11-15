import 'package:flutter/foundation.dart';

import '../../models/home_dashboard_model.dart';
import '../../services/home_dashboard_service.dart';

class HomeDashboardController extends ChangeNotifier {
  HomeDashboardController(this._service);

  final HomeDashboardService _service;

  HomeDashboardModel? summary;
  bool loading = false;
  String? error;

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    loading = true;
    if (!refresh || summary == null) error = null;
    notifyListeners();

    try {
      summary = await _service.getSummary();
      error = null;
    } catch (_) {
      error = 'No pudimos actualizar tu resumen.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
