import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/extensions/user_extension.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/payment_activity_item.dart';
import '../../providers/user_provider.dart';
import '../../models/wallet_model.dart';
import '../../services/payment_activity_service.dart';
import '../../services/wallet_service.dart';

import '../../helpers/role_utils.dart';
import '../../ui/themes/colors.dart';

import '../../services/subscription_plan_service.dart';
import '../../services/user_subscription_service.dart';
import '../../widgets/common/animated_refresh_icon.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/info_chip.dart';
import '../../widgets/finance/payment_activity_receipt_sheet.dart';
import '../../widgets/finance/payment_activity_tile.dart';

import 'buy_coins_page.dart';
import 'transactions_page.dart';
import 'subscriptions_page.dart';
import 'cashout_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late PaymentActivityService _activityService;
  late WalletService _walletService;
  Future<WalletModel?>? _walletFuture;
  late UserSubscriptionService _subService;
  late SubscriptionPlanService _planService;
  Future<List<PaymentActivityItem>>? _activityFuture;
  Future<String>? _planFuture;
  String? _loadedUserId;

  void _refreshWallet() {
    _walletFuture = _walletService.getMyWallet();
    _activityFuture = _activityService.getMineActivity(limit: 5);
    _planFuture = _planName();
    setState(() {});
  }

  Future<void> _refreshWalletAfterPayment() async {
    _refreshWallet();

    for (final delay in const [
      Duration(seconds: 2),
      Duration(seconds: 4),
    ]) {
      await Future.delayed(delay);
      if (!mounted) return;
      _refreshWallet();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.read<UserProvider>().authService;
    final userId = context.watch<UserProvider>().user?.id;

    if (userId == null || _loadedUserId == userId) return;

    _activityService = PaymentActivityService(auth);
    _activityFuture = _activityService.getMineActivity(limit: 5);
    _walletService = WalletService(auth);
    _subService = UserSubscriptionService(auth);
    _planService = SubscriptionPlanService(auth);
    _walletFuture = _walletService.getMyWallet();
    _planFuture = _planName();
    _loadedUserId = userId;
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    final user = up.user;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Monedero'),
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: user == null
            ? const AppLoader(message: 'Cargando monedero...')
            : (_walletFuture == null || _activityFuture == null)
                ? const AppLoader(message: 'Cargando monedero...')
                : RefreshIndicator(
                    onRefresh: () async {
                      _refreshWallet();
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FutureBuilder<String>(
                                future: _planFuture,
                                builder: (context, snap) {
                                  return _PlanPill(
                                    plan: snap.data ?? 'Cargando...',
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: FutureBuilder<WalletModel?>(
                              future: _walletFuture,
                              builder: (context, snap) {
                                final balance = snap.data?.balance;

                                return _WalletBalanceCard(
                                  balance: balance,
                                  displayName: user.displayName,
                                  role: getRoleLabel(user.role),
                                );
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _WalletActionButton(
                                    label: 'Comprar\nMonedas',
                                    icon: Icons.add_circle,
                                    isPrimary: true,
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const BuyCoinsPage(),
                                        ),
                                      );

                                      if (result != null && mounted) {
                                        await _refreshWalletAfterPayment();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _WalletActionButton(
                                    label: 'Transacciones',
                                    icon: Icons.receipt_long,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TransactionsPage(),
                                        ),
                                      );
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _WalletActionButton(
                                    label: 'Suscripciones',
                                    icon: Icons.subscriptions_rounded,
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SubscriptionsPage(),
                                        ),
                                      );

                                      if (result != null && mounted) {
                                        await _refreshWalletAfterPayment();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CashoutPage(),
                                    ),
                                  );
                                  if (mounted) _refreshWallet();
                                },
                                icon: const Icon(Icons.currency_exchange),
                                label: const Text('Retirar Tinkus'),
                              ),
                            ),
                          ),
                        ),
                        // Últimos movimientos
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                            child: Row(
                              children: [
                                const Text(
                                  'Últimos movimientos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                AnimatedRefreshIcon(
                                  onTap: () {
                                    setState(() {
                                      _activityFuture = _activityService
                                          .getMineActivity(limit: 5);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        FutureBuilder<List<PaymentActivityItem>>(
                          future: _activityFuture,
                          builder: (context, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            }

                            if (snap.hasError) {
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(userFacingError(snap.error!)),
                                ),
                              );
                            }

                            final items = snap.data ?? [];

                            if (items.isEmpty) {
                              return const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text('Sin movimientos aún'),
                                ),
                              );
                            }

                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final item = items[i];

                                  return PaymentActivityTile(
                                    item: item,
                                    onTap: () => showPaymentActivityReceipt(
                                        context, item),
                                  );
                                },
                                childCount: items.length,
                              ),
                            );
                          },
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      ],
                    ),
                  ),
      ),
    );
  }

  // —— Presentación —— //

  Future<String> _planName() async {
    final sub = await _subService.getCurrent();
    if (sub == null) return 'Sin plan activo';

    final active = sub.status.name == 'active' &&
        (sub.endDate == null || sub.endDate!.isAfter(DateTime.now()));

    if (!active) return 'Sin plan activo';

    final plan = await _planService.getById(sub.planId);
    return plan?.name ?? 'Sin plan activo';
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.plan});

  final String plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium,
              color: AppColors.mustard, size: 18),
          const SizedBox(width: 6),
          Text(
            'Plan: $plan',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({
    required this.balance,
    required this.displayName,
    required this.role,
  });

  final double? balance;
  final String displayName;
  final String role;

  @override
  Widget build(BuildContext context) {
    final balanceText =
        balance == null ? 'Cargando...' : 'T. ${balance!.toStringAsFixed(1)}';

    return Container(
      height: 188,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBlue,
            AppColors.mediumBlue,
            AppColors.navyBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -8,
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 12,
                ),
              ),
              child: Center(
                child: Text(
                  'T',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.10),
                    fontSize: 76,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu saldo Tinku',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                balanceText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoChip(
                    icon: Icons.person,
                    text: displayName,
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    textColor: AppColors.textPrimary,
                    iconColor: AppColors.textSecondary,
                  ),
                  InfoChip(
                    icon: Icons.verified_user,
                    text: 'Usuario: $role',
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    textColor: AppColors.textPrimary,
                    iconColor: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  const _WalletActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppColors.darkBlue : AppColors.surfaceSoft;
    final fgColor = isPrimary ? Colors.white : AppColors.darkBlue;
    final borderColor = isPrimary
        ? AppColors.darkBlue
        : AppColors.lightBlue.withValues(alpha: 0.32);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fgColor, size: 24),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
