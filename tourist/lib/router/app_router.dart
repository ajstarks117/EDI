import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/auth/presentation/providers/auth_state_provider.dart';
import '../features/blockchain/presentation/screens/blockchain_loading_screen.dart';
import '../features/blockchain/presentation/screens/my_digital_id_screen.dart';
import '../features/tourist/presentation/screens/dashboard_shell_screen.dart';
import '../features/tourist/presentation/screens/home_screen.dart';
import '../features/tourist/presentation/screens/contacts_screen.dart';
import '../features/tourist/presentation/screens/map_screen.dart';
import '../features/tourist/presentation/screens/itinerary_screen.dart';
import '../features/tourist/presentation/screens/settings_screen.dart';
import '../features/tourist/presentation/screens/sos_screen.dart';
import '../features/tourist/presentation/screens/ai_safety_assistant_screen.dart';
import '../features/sos/presentation/screens/sos_active_screen.dart';

// Navigator keys for each shell branch
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorContactsKey = GlobalKey<NavigatorState>(debugLabel: 'shellContacts');
final _shellNavigatorMapKey = GlobalKey<NavigatorState>(debugLabel: 'shellMap');
final _shellNavigatorItineraryKey = GlobalKey<NavigatorState>(debugLabel: 'shellItinerary');
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

final routerProvider = Provider<GoRouter>((ref) {
  final routerListenable = ref.watch(routerListenableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: routerListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      final isWelcome = state.matchedLocation == '/welcome';
      final isLogin = state.matchedLocation == '/login';
      final isOtp = state.matchedLocation == '/otp';
      final isProfileSetup = state.matchedLocation == '/profile-setup';

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isProfileComplete = authState.isProfileComplete;

      if (!isAuthenticated) {
        if (!isWelcome && !isLogin && !isOtp) {
          return '/welcome';
        }
        return null;
      }

      if (!isProfileComplete) {
        if (!isProfileSetup) {
          return '/profile-setup';
        }
        return null;
      }

      if (isWelcome || isLogin || isOtp || isProfileSetup) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile-setup',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'];
          return ProfileSetupScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/blockchain-loading',
        builder: (context, state) => const BlockchainLoadingScreen(),
      ),

      // Standalone screens (outside shell, with back button)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/digital-id',
        builder: (context, state) => const MyDigitalIdScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/ai-assistant',
        builder: (context, state) => const AiSafetyAssistantScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sos',
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sos-active',
        builder: (context, state) => const SosActiveScreen(),
      ),

      // Main dashboard shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Contacts tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorContactsKey,
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (context, state) => const ContactsScreen(),
              ),
            ],
          ),
          // Map tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMapKey,
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          // Itinerary tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorItineraryKey,
            routes: [
              GoRoute(
                path: '/itinerary',
                builder: (context, state) => const ItineraryScreen(),
              ),
            ],
          ),
          // Settings tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

final routerListenableProvider = Provider<RouterListenable>((ref) {
  return RouterListenable(ref);
});

class RouterListenable extends ChangeNotifier {
  final Ref _ref;

  RouterListenable(this._ref) {
    _ref.listen(
      authNotifierProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}
