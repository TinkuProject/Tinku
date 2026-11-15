import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../config/config.dart';
import '../../controllers/subscription/subscriptions_controller.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/subscription_plan_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/media_service.dart';
import '../../services/payment_request_service.dart';
import '../../services/payment_service.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/storage_service.dart';
import '../../services/subscription_plan_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/inputs/receipt_uploader.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  late SubscriptionsController _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    _controller = SubscriptionsController(
      planService: SubscriptionPlanService(auth),
      paymentService: PaymentService(auth),
      paymentRequestService: PaymentRequestService(auth),
      storageService: StorageService(auth),
      mediaService: MediaService(auth),
      stripePaymentService: StripePaymentService(auth),
    );

    _controller.loadPlans();

    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _buy(UserModel user) async {
    try {
      await _controller.buy(user);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar("Solicitud enviada para revisión."),
      );

      Navigator.pop(context, "Solicitud enviada correctamente");
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    }
  }

  Widget _buildLoading() {
    return const AppLoader(message: 'Cargando suscripciones...');
  }

  Future<void> _payWithStripe() async {
    try {
      await _controller.payWithStripe();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar("Pago procesado. Tu suscripción se activará en breve."),
      );

      Navigator.pop(context, "Pago procesado correctamente");
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No hay planes disponibles en este momento'),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel p) {
    final selected = _controller.selectedPlanId == p.id.toString();
    final index = _controller.visiblePlans.indexOf(p);
    final isBest = index == _controller.visiblePlans.length - 1;

    bool isAnniversary(SubscriptionPlanModel plan) =>
        plan.name.toLowerCase().contains('aniversario');

    SubscriptionPlanModel? previousComparablePlan() {
      for (int i = index - 1; i >= 0; i--) {
        if (!isAnniversary(_controller.visiblePlans[i])) {
          return _controller.visiblePlans[i];
        }
      }
      return null;
    }

    final prevPlan = previousComparablePlan();
    final showComparison =
        prevPlan != null &&
            !isAnniversary(p) &&
            p.includedTinku > prevPlan.includedTinku;

    final tinkuDiff = showComparison ? p.includedTinku - prevPlan.includedTinku : 0;
    final priceDiff = showComparison ? p.price - prevPlan.price : 0.0;

    final int baseTinku = p.price.round();
    final int bonusTinku = p.includedTinku - baseTinku;
    final bool hasBonus = bonusTinku > 0;

    final double shadowStrength = isBest ? 0.28 : 0.14;
    final double blur = isBest ? 18 : 10;
    final double spread = isBest ? 2 : 0.5;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () => _controller.selectPlan(p.id.toString()),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isBest
                  ? const LinearGradient(
                colors: [Color(0xFFEAF0FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isBest ? null : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected || isBest
                    ? AppColors.darkBlue
                    : const Color(0xFFE5EAF5),
                width: isBest ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkBlue.withValues(alpha: shadowStrength),
                  blurRadius: blur,
                  spreadRadius: spread,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Radio<String>(
                      value: p.id.toString(),
                      // ignore: deprecated_member_use
                      groupValue: _controller.selectedPlanId,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        if (value != null) {
                          _controller.selectPlan(value);
                        }
                      },
                      activeColor: AppColors.darkBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "${p.price.toStringAsFixed(2)} Bs",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Incluye ${p.includedTinku} tinku • ${p.durationMonths} mes(es)",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasBonus)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            size: 18,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "+$bonusTinku tinku GRATIS",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showComparison)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDE5FF)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            size: 18,
                            color: AppColors.darkBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Mejor que ${prevPlan.name}: "
                                  "+$tinkuDiff tinku por solo +${priceDiff.toStringAsFixed(2)} Bs",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isAnniversary(p))
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.celebration, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    "EDICIÓN ANIVERSARIO",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isBest && !isAnniversary(p))
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "MEJOR OPCIÓN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: "Suscripciones"),
        body: Center(child: Text("No se encontró el usuario.")),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final plans = _controller.visiblePlans;
        final qrUrl = _controller.selectedQrUrl;
        final selectedPlan = _controller.selectedPlan;
        final stripeConfigured = Config.stripePublishableKey.isNotEmpty;

        return Scaffold(
          appBar: const CustomAppBar(title: "Suscripciones"),
          body: _controller.loading
              ? _buildLoading()
              : plans.isEmpty
              ? _buildEmptyState()
              : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Elige tu plan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: plans.map(_buildPlanCard).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5EAF5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.summarize_rounded,
                      color: AppColors.darkBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vas a comprar ${selectedPlan?.name ?? 'un plan'}',
                      ),
                    ),
                    Text(
                      '${selectedPlan?.price.toStringAsFixed(2) ?? "0"} Bs',
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
                        onPressed:
                            stripeConfigured && _controller.canPayWithStripe
                                ? _payWithStripe
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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
                  leading: const Icon(
                    Icons.qr_code_2,
                    color: AppColors.darkBlue,
                  ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          "Escanea el QR para pagar",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Image.network(
                            qrUrl,
                            height: 200,
                            width: 200,
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
                        onPressed:
                            _controller.canSubmit ? () => _buy(user) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkBlue,
                          foregroundColor: Colors.white,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.lock),
                        label: Text(
                          _controller.saving
                              ? 'Enviando...'
                              : selectedPlan != null
                                  ? "Enviar comprobante"
                                  : "Confirmar pago",
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
