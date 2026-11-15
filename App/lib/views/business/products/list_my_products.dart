import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../components/utils.dart';
import '../../../controllers/category/category_controller.dart';
import '../../../controllers/product/product_controller.dart';
import '../../../core/enums.dart';
import '../../../models/product_model.dart';
import '../../../providers/user_provider.dart';
import '../../../services/business_service.dart';
import '../../../services/category_service.dart';
import '../../../services/media_service.dart';
import '../../../services/product_service.dart';
import '../../../widgets/bars/filter_bar_products.dart';
import '../../../widgets/common/actions/app_fab.dart';
import '../../../widgets/common/actions/confirm_delete_action.dart';
import '../../../widgets/common/filtered_empty.dart';
import '../../../widgets/common/initial_empty_state.dart';
import '../../../widgets/common/loaders/app_loader.dart';
import '../../../widgets/common/navigation/custom_app_bar.dart';
import '../../../widgets/product/product_manage_card.dart';
import '../../../widgets/selectors/business_selector_dialog.dart';

import 'product_form.dart';

class ListProductsPage extends StatefulWidget {
  const ListProductsPage({super.key});

  @override
  State<ListProductsPage> createState() => _ListProductsPageState();
}

class _ListProductsPageState extends State<ListProductsPage> {
  late ProductController c;
  late CategoryController categoryController;

  bool _initialized = false;
  String? _loadedUserId;
  Map<int, String> _categories = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userProvider = context.watch<UserProvider>();
    final userId = userProvider.user?.id;
    if (_initialized && _loadedUserId == userId) return;

    if (_initialized) {
      c.removeListener(_rebuild);
      categoryController.removeListener(_rebuild);
      c.reset();
      categoryController.dispose();
    }

    final auth = userProvider.authService;

    c = ProductController(
      ProductService(auth),
      BusinessService(auth),
      MediaService(auth),
    );

    categoryController = CategoryController(
      CategoryService(auth),
    );

    c.addListener(_rebuild);
    categoryController.addListener(_rebuild);
    _loadedUserId = userId;
    _categories = {};

    Future.microtask(() async {
      await c.loadMine();
      await categoryController.load(CategoryEntityType.product);

      if (!mounted) return;
      setState(() {
        _categories = {
          for (final cat in categoryController.categories) cat.id: cat.name,
        };
      });
    });

    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      c.removeListener(_rebuild);
      categoryController.removeListener(_rebuild);
      c.dispose();
      categoryController.dispose();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _openCreateProduct() async {
    if (!c.hasBusinesses) {
      showSnackbar("No tienes negocios disponibles.");
      return;
    }

    final items = Map<int, String>.from(c.businessSelectorItems)..remove(0);

    final selected = await showBusinessSelectorDialog(
      context: context,
      businessItems: items,
      disabledIds: c.disabledBusinessSelectorIds,
      disabledLabel: 'Pendiente',
      title: "Seleccionar negocio",
    );

    if (!mounted || selected == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          businessId: selected,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      showSnackbar("Producto creado correctamente.");
      await c.refresh();
    }
  }

  Future<void> _confirmDelete(ProductModel product) async {
    await confirmAndDelete(
      context: context,
      title: '¿Eliminar producto?',
      message: '¿Seguro que deseas eliminar "${product.name}"?',
      onDelete: () => c.softDeleteProduct(product),
      successMessage: 'Producto eliminado',
      errorMessage: 'Error al eliminar el producto',
    );
  }

  Future<void> _editProduct(ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          businessId: product.businessId,
          product: product,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      showSnackbar("Producto actualizado correctamente.");
      await c.refresh();
    }
  }

  ({String label, Color color, IconData icon}) _statusMeta(ProductModel p) {
    switch (p.status) {
      case ProductStatus.active:
        return (
        label: 'Activo',
        color: Colors.green,
        icon: Icons.check_circle,
        );
      case ProductStatus.out_of_stock:
        return (
        label: 'Sin stock',
        color: Colors.orange,
        icon: Icons.inventory_2_outlined,
        );
      case ProductStatus.inactive:
        return (
        label: 'Inactivo',
        color: Colors.grey,
        icon: Icons.pause_circle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = c.loading;
    final hasData = c.hasData;
    final filtered = c.filteredProducts;
    final isFilteredEmpty = filtered.isEmpty && hasData;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Productos'),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: FilterBarProducts(
                  order: c.filterOrder,
                  business: c.selectedBusiness,
                  businessItems: c.businessSelectorItems,
                  onOrder: c.setFilterOrder,
                  onBusiness: c.setSelectedBusiness,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const SizedBox.shrink()
                    : !hasData
                    ? InitialEmptyState(
                  icon: FontAwesomeIcons.box,
                  title: "No tienes productos",
                  description:
                  "Crea tu primer producto eligiendo un negocio.",
                  actionLabel: "Crear producto",
                  onCreate: _openCreateProduct,
                )
                    : isFilteredEmpty
                    ? FilteredEmptyState(
                  title: "No hay productos con estos filtros",
                  subtitle:
                  "Prueba cambiando los filtros o limpiándolos",
                  onAction: () {
                    c.resetFilters();
                  },
                )
                    : RefreshIndicator(
                  onRefresh: c.refresh,
                  child: ListView.builder(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      0,
                      12,
                      100,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final meta = _statusMeta(product);

                      final imageUrl = c.imageFor(product.id) ?? '';

                      final categoryName =
                          _categories[product.categoryId] ??
                              'Sin categoría';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                        ),
                        child: ProductManageCard(
                          title: product.name,
                          category: categoryName,
                          business: c.businessNameFor(product.businessId),
                          imageUrl: imageUrl,
                          statusLabel: meta.label,
                          statusColor: meta.color,
                          statusIcon: meta.icon,
                          description: product.description,
                          price: product.price != null ? 'Bs ${product.price!.toStringAsFixed(2)}' : null,
                          tinkuPrice: product.tinkuPrice != null
                              ? 'T ${product.tinkuPrice!.toStringAsFixed(2)}'
                              : null,
                          stock: product.stock?.toString(),
                          onEdit: () => _editProduct(product),
                          onDelete: () => _confirmDelete(product),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (isLoading)
            const AppLoader(
              message: "Cargando tus productos...",
            ),
        ],
      ),
      floatingActionButton: !hasData
          ? null
          : AppFAB(
        icon: FontAwesomeIcons.plus,
        label: "Agregar producto",
        onPressed: _openCreateProduct,
      ),
    );
  }
}
