import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../config/config.dart';
import '../../controllers/coin_package/coin_package.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/coin_package_service.dart';
import '../../services/media_service.dart';
import '../../services/payment_request_service.dart';
import '../../services/payment_service.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/storage_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/inputs/receipt_uploader.dart';

class BuyCoinsPage extends StatefulWidget {
  const BuyCoinsPage({super.key});

  @override
  State<BuyCoinsPage> createState() => _BuyCoinsPageState();
}

class _BuyCoinsPageState extends State<BuyCoinsPage> {
  late BuyCoinsController _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    _controller = BuyCoinsController(
      coinPackageService: CoinPackageService(auth),
      paymentService: PaymentService(auth),
      paymentRequestService: PaymentRequestService(auth),
      storageService: StorageService(auth),
      mediaService: MediaService(auth),
      stripePaymentService: StripePaymentService(auth),
    );

    _controller.loadPackages();

    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend(UserModel user) async {
    try {
      await _controller.confirmAndBuy(user);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar('Solicitud enviada para revisión.'),
      );

      Navigator.of(context).pop('Solicitud enviada correctamente');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    }
  }

  Widget _buildLoading() {
    return const AppLoader(message: 'Cargando paquetes...');
  }

  Future<void> _handleStripePayment() async {
    try {
      await _controller.payWithStripe();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar('Pago procesado. Tus Tinkus se acreditarán en breve.'),
      );

      Navigator.of(context).pop('Pago procesado correctamente');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    }
  }

  Widget _buildEmptyUser() {
    return const Center(child: Text("No se encontró el usuario."));
  }

  Widget _buildPackCard({
    required BuildContext context,
    required dynamic pack,
    required bool selected,
    required bool isBest,
    required bool isMostSold,
  }) {
    final int baseCoins = pack.cashAmount.round();
    final int bonusCoins = pack.tinkusAmount - baseCoins;
    final bool hasBonus = bonusCoins > 0;

    final double shadowStrength = isBest ? 0.28 : 0.16;
    final double blur = isBest ? 18 : 10;

    return GestureDetector(
      onTap: () => _controller.selectPack(pack),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isBest
              ? const LinearGradient(
            colors: [Color(0xFFEAF0FF), Colors.white],
          )
              : null,
          color: isBest ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.darkBlue : const Color(0xFFE5EAF5),
            width: selected || isBest ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlue.withValues(alpha: shadowStrength),
              blurRadius: blur,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMostSold || isBest)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBest ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _capitalize(isBest ? 'mejor valor' : 'más vendido'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            Text(
              _capitalize(pack.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${pack.tinkusAmount} monedas",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${pack.cashAmount.toStringAsFixed(2)} Bs",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            if (hasBonus)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard,
                          size: 15, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        "+$bonusCoins gratis",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(UserModel user) {
    final packs = _controller.visiblePacks
        .where(
          (p) => p.name.trim().toLowerCase() != 'partner_upgrade',
    )
        .toList();
    final selectedPack = _controller.selectedPack;
    final qrUrl = _controller.selectedQrUrl;
    final stripeConfigured = Config.stripePublishableKey.isNotEmpty;

    if (_controller.loading) {
      return _buildLoading();
    }

    if (packs.isEmpty) {
      return const Center(
        child: Text('No hay paquetes disponibles en este momento'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Elige tu paquete',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: packs.map((p) {
            final selected = selectedPack?.id == p.id;
            final isBest = p == packs.last;
            final isMostSold = packs.length > 2 && p == packs[packs.length ~/ 2];

            return _buildPackCard(
              context: context,
              pack: p,
              selected: selected,
              isBest: isBest,
              isMostSold: isMostSold,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5EAF5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.summarize_rounded, color: AppColors.darkBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vas a comprar ${selectedPack?.tinkusAmount ?? 0} monedas',
                ),
              ),
              Text(
                '${selectedPack?.cashAmount.toStringAsFixed(2) ?? "0"} Bs',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5EAF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.credit_card, color: AppColors.darkBlue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pago con tarjeta',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stripeConfigured
                    ? 'Paga de forma segura mediante Stripe.'
                    : 'Esta versión de la app no tiene Stripe configurado.',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: stripeConfigured && _controller.canPayWithStripe
                      ? _handleStripePayment
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.darkBlue.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _controller.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.credit_card),
                  label: Text(
                    _controller.saving
                        ? 'Procesando...'
                        : 'Pagar con tarjeta',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (qrUrl != null) ...[
          const SizedBox(height: 16),
          ExpansionTile(
            initiallyExpanded: !stripeConfigured,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            leading: const Icon(Icons.qr_code_2, color: AppColors.darkBlue),
            title: const Text(
              'Pago con QR',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              stripeConfigured
                  ? 'Úsalo solo si no puedes pagar con tarjeta.'
                  : 'Sube tu comprobante para revisión administrativa.',
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Escanea el código QR para pagar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Image.network(
                      qrUrl,
                      height: 220,
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ReceiptUploader(
                onChanged: (file) {
                  _controller.setReceiptFile(file);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _controller.canSubmit
                      ? () => _handleSend(user)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.darkBlue.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _controller.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.lock),
                  label: Text(
                    _controller.saving
                        ? 'Enviando...'
                        : _controller.selectedPack != null
                            ? 'Enviar comprobante'
                            : 'Confirmar compra',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return _buildEmptyUser();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: const CustomAppBar(title: 'Comprar Monedas'),
          body: _controller.loading ? _buildLoading() : _buildBody(user),
        );
      },
    );
  }
}
