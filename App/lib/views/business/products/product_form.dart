import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/utils.dart';
import '../../../controllers/product/product_form_controller.dart';
import '../../../models/product_model.dart';
import '../../../providers/user_provider.dart';
import '../../../services/category_service.dart';
import '../../../services/media_service.dart';
import '../../../services/product_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/common/loaders/app_loader.dart';
import '../../../widgets/common/navigation/custom_app_bar.dart';
import '../../../widgets/product/form/product_form_layout.dart';

class ProductFormPage extends StatefulWidget {
  final int businessId;
  final ProductModel? product;

  const ProductFormPage({
    super.key,
    required this.businessId,
    this.product,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late ProductFormController c;
  bool _initialized = false;

  bool get editing => widget.product != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    c = ProductFormController(
      productService: ProductService(auth),
      categoryService: CategoryService(auth),
      storageService: StorageService(auth),
      mediaService: MediaService(auth),
      businessId: widget.businessId,
      product: widget.product,
    );

    c.addListener(_rebuild);

    Future.microtask(() async {
      await c.load();
    });

    _initialized = true;
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    c.reset();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      showSnackbar("Completa los campos requeridos");
      return;
    }

    try {
      await c.save();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      showSnackbar("Error al guardar el producto");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: editing ? "Editar Producto" : "Agregar Producto",
      ),
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: ProductFormLayout(
              c: c,
              formKey: _formKey,
              onSubmit: _submit,
            ),
          ),

          if (c.loading)
            AppLoader(
              message: editing
                  ? "Cargando producto..."
                  : "Cargando formulario...",
            ),
        ],
      ),
    );
  }
}