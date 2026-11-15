import 'dart:async';

import 'package:flutter/material.dart';
import 'core/app_initializer.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/providers/notification_provider.dart';
import 'package:tinkuapp/views/business/admin_pending_businesses_page.dart';
import 'package:tinkuapp/views/business/certifications/list_my_certifications.dart';
import 'package:tinkuapp/views/business/admin_business_claims_page.dart';
import 'package:tinkuapp/views/business/business_claim_page.dart';
import 'package:tinkuapp/views/business/discount/list_my_discounts.dart';
import 'package:tinkuapp/views/business/products/list_my_products.dart';
import 'package:tinkuapp/views/event/admin_pending_events_page.dart';
import 'package:tinkuapp/views/event/event_form.dart';
import 'package:tinkuapp/views/marketplace/admin_pending_warehouses_page.dart';
import 'package:tinkuapp/views/user/become_partner_page.dart';
import '../components/drawer.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/network_status_service.dart';
import 'widgets/common/network_connection_gate.dart';
import 'widgets/common/navigation/main_navigation_shell.dart';
import 'controllers/shared/notification/notification_controller.dart';
import 'core/navigation.dart';
import 'views/splash_screen.dart';
import 'views/login.dart';
import 'views/register.dart';
import 'views/touristPlaces/tourist_places_list.dart';
import 'views/support/about_us.dart';
import 'views/support/help.dart';
import 'views/transport/public_transport_routes_page.dart';
import 'views/marketplace/my_marketplace_page.dart';
import 'views/marketplace/marketplace_sales_orders_page.dart';
import 'views/marketplace/warehouses_page.dart';
import 'views/reviews/manage_reviews_page.dart';
import '../ui/themes/colors.dart';
import 'views/user/change_password.dart';
import 'views/user/favourite.dart';
import 'views/user/notification.dart';
import 'views/wallet/charging_point.dart';
import 'views/wallet/balance.dart';
import 'views/wallet/admin_cashout_requests_page.dart';

import 'views/business/list_my_business.dart';

import 'views/event/list_my_events.dart';
import 'views/event/all_events.dart';
import 'views/event/my_calendar.dart';

import 'views/boost/list_my_boosts.dart';
import 'components/utils.dart';
import 'core/route_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = AppInitializer.create();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: deps.authService),
        Provider<NotificationService>(
          create: (context) => NotificationService(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<UserProvider>.value(
          value: deps.userProvider,
        ),
        ChangeNotifierProvider<NetworkStatusService>.value(
          value: deps.networkStatusService,
        ),
        ChangeNotifierProvider(
          create: (context) {
            final provider = NotificationProvider(
              context.read<NotificationService>(),
              deps.pushNotificationService,
            );

            if (deps.userProvider.user != null) {
              Future.microtask(provider.loadUnreadCount);
            }

            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) =>
              NotificationController(context.read<NotificationService>()),
        ),
      ],
      child: const OverlaySupport.global(
        child: MyApp(),
      ),
    ),
  );

  unawaited(AppInitializer.initializeDeferred(deps));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => NetworkConnectionGate(
        child: child ?? const SizedBox.shrink(),
      ),
      navigatorObservers: [routeObserver],
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: rootMessengerKey,
      title: 'Tinku',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.darkBlue,
          primary: AppColors.darkBlue,
        ),
        primaryColor: AppColors.darkBlue,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.darkBlue,
          selectionColor: AppColors.darkBlue.withValues(alpha: 0.25),
          selectionHandleColor: AppColors.darkBlue,
        ),
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelStyle: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.w600,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.darkBlue,
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          backgroundColor: AppColors.surface,
          contentTextStyle: const TextStyle(
            color: AppColors.darkBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          actionTextColor: AppColors.darkBlue,
          disabledActionTextColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide.none,
          ),
          insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: AppColors.pureWhite,
          titleTextStyle: TextStyle(
            color: AppColors.pureWhite,
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.pureWhite),
        ),
      ),
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const MenuZoom(mainScreen: SplashScreen()),
        '/login': (context) => const MenuZoom(mainScreen: LoginPage()),
        '/register': (context) => const MenuZoom(mainScreen: RegisterPage()),
        '/changePassword': (_) => const ChangePasswordPage(),

        '/home': (context) => const MenuZoom(
              mainScreen: MainNavigationShell(),
            ),
        '/search': (context) => const MenuZoom(
              mainScreen: MainNavigationShell(
                initialDestination: MainNavigationDestination.explore,
              ),
            ),
        '/transportRoutes': (context) =>
            const MenuZoom(mainScreen: PublicTransportRoutesPage()),
        '/marketplace': (context) => const MenuZoom(
              mainScreen: MainNavigationShell(
                initialDestination: MainNavigationDestination.marketplace,
              ),
            ),
        '/myMarketplaceOrders': (context) => const MenuZoom(
              mainScreen: MainNavigationShell(
                initialDestination: MainNavigationDestination.activity,
              ),
            ),
        '/touristPlaces': (context) =>
            const MenuZoom(mainScreen: TouristPlaces()),

        '/becomePartner': (context) =>
            const MenuZoom(mainScreen: BecomePartnerPage()),
        '/claimBusiness': (context) =>
            const MenuZoom(mainScreen: BusinessClaimPage()),
        '/adminBusinessClaims': (context) =>
            const MenuZoom(mainScreen: AdminBusinessClaimsPage()),
        '/adminPendingBusinesses': (context) =>
            const MenuZoom(mainScreen: AdminPendingBusinessesPage()),
        '/adminPendingEvents': (context) =>
            const MenuZoom(mainScreen: AdminPendingEventsPage()),
        '/adminPendingWarehouses': (context) =>
            const MenuZoom(mainScreen: AdminPendingWarehousesPage()),
        '/profile': (context) => const MenuZoom(
              mainScreen: MainNavigationShell(
                initialDestination: MainNavigationDestination.account,
              ),
            ),
        '/favourites': (context) =>
            const MenuZoom(mainScreen: FavoriteBusinessesPage()),

        '/myEvents': (context) => const MenuZoom(mainScreen: EventsListPage()),
        '/addEvent': (context) => const MenuZoom(mainScreen: EventFormPage()),
        '/allEvents': (context) => const MenuZoom(mainScreen: AllEventsPage()),
        '/myCalendar': (context) =>
            const MenuZoom(mainScreen: MyCalendarPage()),

        '/myBusinesses': (context) =>
            const MenuZoom(mainScreen: MyBusinessesPage(type: 'business')),
        //'/news' : (context) => const MenuZoom(mainScreen: AllPromotionsPage()),
        '/myNews': (context) => const MenuZoom(mainScreen: ListMyBoostsPage()),
        '/myPromotions': (context) =>
            const MenuZoom(mainScreen: MyDiscountsListPage()),
        '/notifications': (context) =>
            const MenuZoom(mainScreen: NotificationsPage()),

        '/myServices': (_) =>
            const MenuZoom(mainScreen: MyBusinessesPage(type: 'service')),
        '/myProducts': (_) => const MenuZoom(mainScreen: ListProductsPage()),
        '/myMarketplace': (_) =>
            const MenuZoom(mainScreen: MyMarketplacePage()),
        '/marketplaceSalesOrders': (_) =>
            const MenuZoom(mainScreen: MarketplaceSalesOrdersPage()),
        '/warehouses': (_) => const MenuZoom(mainScreen: WarehousesPage()),
        '/manageReviews': (_) =>
            const MenuZoom(mainScreen: ManageReviewsPage()),
        '/myCertifications': (_) =>
            const MenuZoom(mainScreen: ListCertificationsPage()),

        '/walletBalance': (context) => const MenuZoom(mainScreen: WalletPage()),
        '/adminCashoutRequests': (_) =>
            const MenuZoom(mainScreen: AdminCashoutRequestsPage()),
        '/chargingPoints': (context) =>
            const MenuZoom(mainScreen: ChargingPointsMapPage()),

        '/help': (context) => const MenuZoom(mainScreen: HelpPage()),
        '/about': (context) => const MenuZoom(mainScreen: AboutPage()),
      },
    );
  }
}
