import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/services/system_config_service.dart';

import '../../../components/utils.dart';
import '../../../helpers/error_message_helper.dart';

import '../../../controllers/discount/discount_controller.dart';
import '../../../controllers/discount/discount_form_controller.dart';
import '../../../controllers/shared/media/media_controller.dart';

import '../../../models/discount_model.dart';

import '../../../providers/user_provider.dart';

import '../../../services/business_service.dart';
import '../../../services/discount_service.dart';
import '../../../services/media_service.dart';
import '../../../services/storage_service.dart';

import '../../../widgets/common/loaders/app_loader.dart';
import '../../../widgets/common/navigation/custom_app_bar.dart';
import '../../../widgets/discount/forms/discount_form_layout.dart';

class DiscountFormPage extends StatefulWidget {
  final int businessId;
  final DiscountModel? discount;

  const DiscountFormPage({
    super.key,
    required this.businessId,
    this.discount,
  });

  @override
  State<DiscountFormPage> createState() =>
      _DiscountFormPageState();
}

class _DiscountFormPageState
    extends State<DiscountFormPage> {
  late DiscountFormController c;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    final discountController = DiscountController(
        discountService: DiscountService(auth),
        businessService: BusinessService(auth),
        systemConfigService: SystemConfigService(auth),
        mediaService: MediaService(auth)
    );

    final mediaController = MediaController(
      StorageService(auth),
      MediaService(auth),
    );

    c = DiscountFormController(
      discountController,
      mediaController,
    );

    c.addListener(_rebuild);

    Future.microtask(() async {
      await c.init(
        businessId: widget.businessId,
        discount: widget.discount,
      );
    });

    _initialized = true;
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    c.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    try {
      if (!c.formKey.currentState!.validate()) {
        return;
      }

      if (!c.editing && c.selectedDays > 0) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmar promoción'),
            content: Text(
              'Se descontarán ${c.estimatedCreateCost.toStringAsFixed(0)} T de tu monedero '
              'por ${c.selectedDays} días de publicación.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Crear'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      final ok = await c.submit(
        businessId: widget.businessId,
      );

      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      showSnackbar(userFacingError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: c.editing ? 'Editar Promoción' : 'Agregar Promoción',
      ),
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          DiscountFormLayout(
            c: c,
            onSubmit: _submit,
          ),
          if (c.loading)
            const AppLoader(message: "Cargando promoción..."),
        ],
      ),
    );
  }
}
