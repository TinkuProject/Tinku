import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/payment_activity_item.dart';
import '../../helpers/error_message_helper.dart';
import '../../services/payment_activity_service.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/finance/payment_activity_receipt_sheet.dart';
import '../../widgets/finance/payment_activity_tile.dart';
import '../../providers/user_provider.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  PaymentActivityService? _service;
  final List<PaymentActivityItem> _items = [];
  String? _loadedUserId;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  static const int _pageSize = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.read<UserProvider>().authService;
    final userId = context.watch<UserProvider>().user?.id;

    if (userId == null || _loadedUserId == userId) return;

    _service = PaymentActivityService(auth);
    _loadedUserId = userId;
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    final service = _service;
    if (service == null || _loadingMore) return;

    if (reset) {
      _offset = 0;
      _hasMore = true;
      setState(() {
        _loading = _items.isEmpty;
        _error = null;
      });
    } else {
      if (!_hasMore) return;
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }

    try {
      final page = await service.getMineActivityPage(
        limit: _pageSize,
        offset: _offset,
      );

      if (!mounted) return;

      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _offset = _items.length;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = userFacingError(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Transacciones'),
      body: user == null
          ? const AppLoader(message: 'Cargando transacciones...')
          : _loading
              ? const AppLoader(message: 'Cargando transacciones...')
              : _error != null && _items.isEmpty
                  ? Center(child: Text(_error!))
                  : _items.isEmpty
                      ? const Center(child: Text('Sin transacciones'))
                      : RefreshIndicator(
                          onRefresh: () => _load(reset: true),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemBuilder: (context, i) {
                              if (i >= _items.length) {
                                if (_error != null) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Column(
                                      children: [
                                        Text(_error!,
                                            textAlign: TextAlign.center),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () => _load(),
                                          child: const Text('Reintentar'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: _loadingMore
                                        ? const CircularProgressIndicator()
                                        : TextButton(
                                            onPressed: () => _load(),
                                            child: const Text('Cargar más'),
                                          ),
                                  ),
                                );
                              }

                              final item = _items[i];

                              return PaymentActivityTile(
                                item: item,
                                onTap: () =>
                                    showPaymentActivityReceipt(context, item),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const Divider(height: 0),
                            itemCount: _items.length +
                                (_hasMore || _error != null ? 1 : 0),
                          ),
                        ),
    );
  }
}
