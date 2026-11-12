import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'presentation/pages/auth/auth_screen.dart';
import 'presentation/pages/patient/appointments_screen.dart';
import 'presentation/pages/patient/booking_screen.dart';
import 'presentation/pages/patient/catalog_screen.dart';
import 'presentation/pages/patient/extra_screens.dart';
import 'presentation/pages/patient/home_screen.dart';
import 'presentation/pages/patient/orders_screen.dart';
import 'presentation/pages/patient/profile_screen.dart';
import 'presentation/pages/patient/search_screen.dart';
import 'presentation/pages/staff/staff_screens.dart';
import 'presentation/state/optiflow_controller.dart';
import 'presentation/navigation/route_access.dart';
import 'core/theme/app_colors.dart';

class OptiFlowApp extends StatefulWidget {
  const OptiFlowApp({super.key});

  @override
  State<OptiFlowApp> createState() => _OptiFlowAppState();
}

class _OptiFlowAppState extends State<OptiFlowApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: context.read<OptiFlowController>(),
    redirect: (context, state) async {
      final app = context.read<OptiFlowController>();
      await app.bootstrap();
      return routeRedirect(app.session, state.uri);
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _BootScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/p/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/p/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/p/appointments', builder: (_, __) => const AppointmentsScreen()),
      GoRoute(path: '/p/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/p/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/p/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/p/catalog', builder: (_, __) => const CatalogScreen()),
      GoRoute(path: '/p/frame/:id', builder: (_, state) => FrameDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/p/tryon/:id', builder: (_, state) => TryOnScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/p/prescription', builder: (_, __) => const PrescriptionScreen(editable: false)),
      GoRoute(path: '/p/prescription/edit', builder: (_, __) => const PrescriptionScreen(editable: true)),
      GoRoute(path: '/p/appointment/:id', builder: (_, state) => AppointmentDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/p/reschedule/:id', builder: (_, state) => RescheduleScreen(id: state.pathParameters['id']!)),
      GoRoute(
        path: '/p/book',
        builder: (_, state) => BookingScreen(storeId: state.uri.queryParameters['storeId']),
      ),
      GoRoute(path: '/p/order/:id', builder: (_, state) => OrderTrackingScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/p/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(
        path: '/p/settings',
        builder: (_, state) => SettingsScreen(staff: state.uri.queryParameters['staff'] == 'true'),
      ),
      GoRoute(path: '/s/home', builder: (_, __) => const StaffDashboardScreen()),
      GoRoute(path: '/s/settings', builder: (_, __) => const SettingsScreen(staff: true)),
      GoRoute(path: '/s/agenda', builder: (_, __) => const StaffAgendaScreen()),
      GoRoute(path: '/s/patients', builder: (_, __) => const StaffPatientsScreen()),
      GoRoute(path: '/s/inventory', builder: (_, __) => const StaffInventoryScreen()),
      GoRoute(path: '/s/more', builder: (_, __) => const StaffMoreScreen()),
      GoRoute(path: '/s/patients/new', builder: (_, __) => const NewPatientScreen()),
      GoRoute(path: '/s/patient/:id', builder: (_, state) => StaffPatientRecordScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/s/appointments/new', builder: (_, state) => NewAppointmentScreen(patientId: state.uri.queryParameters['patientId'])),
      GoRoute(path: '/s/clinical', builder: (_, __) => const ClinicalCareScreen()),
      GoRoute(path: '/s/evaluation', builder: (_, __) => const VisualEvaluationScreen()),
      GoRoute(path: '/s/work-order', builder: (_, __) => const WorkOrderScreen()),
      GoRoute(path: '/s/production', builder: (_, __) => const ProductionScreen()),
      GoRoute(path: '/s/quote', builder: (_, __) => const QuoteScreen()),
      GoRoute(path: '/s/sale', builder: (_, __) => const ConfirmSaleScreen()),
      GoRoute(path: '/s/sale/done', builder: (_, __) => const SaleDoneScreen()),
      GoRoute(path: '/s/scanner', builder: (_, __) => const ScannerScreen()),
      GoRoute(path: '/s/product/:id', builder: (_, state) => ProductDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/s/stock/:id', builder: (_, state) => StockManagementScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/s/movement', builder: (_, state) => NewMovementScreen(sku: state.uri.queryParameters['sku'])),
      GoRoute(path: '/s/alerts', builder: (_, __) => const AlertsScreen()),
      GoRoute(path: '/s/reports', builder: (_, __) => const ReportsScreen()),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.plusJakartaSansTextTheme();
    return MaterialApp.router(
      title: 'OptiFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.screenBg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.electric, primary: AppColors.electric, surface: AppColors.screenBg),
        textTheme: text,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      routerConfig: _router,
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.loginGradientTop,
      body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
    );
  }
}
