import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../../../core/enums.dart';
import '../../../models/user_model.dart';
import '../../../ui/themes/colors.dart';
import '../../../views/explore/explore.dart';
import '../../../views/home.dart';
import '../../../views/home/role_home_dashboard.dart';
import '../../../views/marketplace/marketplace_page.dart';
import '../../../views/marketplace/my_marketplace_orders_page.dart';
import '../../../views/user/menu.dart';
import '../buttons/primary_button.dart';
import '../empty/app_empty.dart';
import 'main_bottom_navigation.dart';

enum MainNavigationDestination {
  home,
  explore,
  marketplace,
  activity,
  account,
}

class MainNavigationShell extends StatefulWidget {
  final MainNavigationDestination initialDestination;

  const MainNavigationShell({
    super.key,
    this.initialDestination = MainNavigationDestination.home,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _selectedIndex;
  final List<Widget?> _pages = List<Widget?>.filled(5, null);
  String? _pagesUserKey;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialDestination.index;
  }

  @override
  void didUpdateWidget(covariant MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDestination != widget.initialDestination) {
      _selectedIndex = widget.initialDestination.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final userKey = user == null ? null : '${user.id}:${user.role.name}';
    if (_pagesUserKey != userKey) {
      _pagesUserKey = userKey;
      _pages[MainNavigationDestination.home.index] = null;
      _pages[MainNavigationDestination.activity.index] = null;
      _pages[MainNavigationDestination.account.index] = null;
    }

    _pages[_selectedIndex] ??= _buildPage(_selectedIndex, user);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          _pages.length,
          (index) => _pages[index] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: MainBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => _select(index, user != null),
      ),
    );
  }

  Widget _buildPage(int index, UserModel? user) {
    final isLoggedIn = user != null;
    return switch (MainNavigationDestination.values[index]) {
      MainNavigationDestination.home => user != null &&
              (user.role == UserRole.partner ||
                  user.role == UserRole.admin ||
                  user.role == UserRole.master)
          ? RoleHomeDashboard(user: user)
          : const HomePage(),
      MainNavigationDestination.explore => const ExplorePage(),
      MainNavigationDestination.marketplace => const MarketplacePage(),
      MainNavigationDestination.activity => isLoggedIn
          ? const MyMarketplaceOrdersPage()
          : const _ActivitySignInRequired(),
      MainNavigationDestination.account =>
        isLoggedIn ? const UserOverviewPage() : const SizedBox.shrink(),
    };
  }

  void _select(int index, bool isLoggedIn) {
    final destination = MainNavigationDestination.values[index];
    if (destination == MainNavigationDestination.account && !isLoggedIn) {
      ZoomDrawer.of(context)?.toggle();
      return;
    }

    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }
}

class _ActivitySignInRequired extends StatelessWidget {
  const _ActivitySignInRequired();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: _ActivityHeader(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Tu actividad estará acá',
                subtitle:
                    'Inicia sesión para consultar tus compras y el estado de tus pedidos.',
                iconColor: AppColors.darkBlue,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Iniciar sesión',
                icon: Icons.login_rounded,
                onTap: () => Navigator.pushNamed(context, '/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Abrir menú',
              child: IconButton(
                onPressed: () => ZoomDrawer.of(context)?.toggle(),
                icon: const Icon(Icons.menu),
                color: AppColors.textPrimary,
                tooltip: 'Abrir menú',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Actividad',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
