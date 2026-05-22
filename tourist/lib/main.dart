import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/hive_service.dart';
import 'core/constants/ui_constants.dart';
import 'features/safety/services/background_tracking.dart';
import 'features/geofence/geofence_notification_service.dart';
import 'features/geofence/geofence_cache_service.dart';
import 'features/geofence/presentation/widgets/geofence_alert_overlay.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/demo_service.dart';

// Async initialization provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  // 1. Initialize Hive (critical for local config/caching)
  await HiveService.init();

  // Seed demo data (only in debug/demo mode, idempotent)
  await DemoService.seedDemoData();

  // 2. Initialize Geofence Caching & Notification Service
  try {
    await GeofenceNotificationService.initialize();
    await GeofenceNotificationService.requestPermissions();

    final cacheService = GeofenceCacheService();
    await cacheService.fetchAndCacheZones();

    await Workmanager().registerPeriodicTask(
      "2",
      GeofenceCacheService.geofenceRefreshTaskName,
      frequency: const Duration(hours: 4),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  } catch (e) {
    debugPrint('Geofence initial sync/Workmanager setup error: $e');
  }

  // 3. Initialize Background Tracking Service
  try {
    await BackgroundTrackingService.initialize();
    final isBacktrackingEnabled = HiveService.settingsBox.get('backtrackingEnabled', defaultValue: true);
    if (isBacktrackingEnabled) {
      await BackgroundTrackingService.startTracking();
    }
  } catch (e) {
    debugPrint('Background tracking service failed to start: $e');
  }

  // 4. Initialize Firebase (non-critical fallback for offline/development testing)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e. Proceeding in mock/offline mode.');
  }
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TravelSureApp(),
    ),
  );
}

class TravelSureApp extends ConsumerWidget {
  const TravelSureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(appInitializationProvider);

    return MaterialApp(
      title: 'TravelSure',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      home: initAsync.when(
        data: (_) => const RouterAppEntry(),
        loading: () => const StartupSplashScreen(),
        error: (error, stack) => StartupErrorScreen(
          error: error.toString(),
          onRetry: () => ref.invalidate(appInitializationProvider),
        ),
      ),
    );
  }
}

// Sub-app containing GoRouter navigation once initialization completes
class RouterAppEntry extends ConsumerWidget {
  const RouterAppEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TravelSure',
      theme: AppTheme.lightTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null)
              Column(
                children: [
                  const ConnectivityBanner(),
                  Expanded(child: child),
                ],
              ),
            const GeofenceAlertOverlay(),
          ],
        );
      },
    );
  }
}

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityStateProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOnline ? 0.0 : (32.0 + topPadding),
      width: double.infinity,
      color: AppColors.warningAmber,
      child: isOnline
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  Container(
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '⚠  OFFLINE — Emergency relay active  ⚠',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class StartupSplashScreen extends StatelessWidget {
  const StartupSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.travel_explore, color: Colors.white, size: 64),
              const SizedBox(height: UiConstants.spaceMD),
              Text(
                'TravelSure',
                style: AppTextStyles.appTitle.copyWith(color: Colors.white),
              ),
              const SizedBox(height: UiConstants.spaceSM),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const StartupErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(UiConstants.spaceLG),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5E1A1A), Color(0xFF8C0D0D)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: UiConstants.spaceMD),
              Text(
                'Initialization Failed',
                style: AppTextStyles.appTitle.copyWith(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: UiConstants.spaceSM),
              Text(
                'Critical services (Hive/secure storage) failed to initialize:\n$error',
                style: AppTextStyles.bodyText.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UiConstants.spaceLG),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: AppColors.alertRed),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.alertRed,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
