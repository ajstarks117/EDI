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

final routerProvider = Provider<GoRouter>((ref) {
  final routerListenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: '/',
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
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'];
          return ProfileSetupScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/blockchain-loading',
        builder: (context, state) => const BlockchainLoadingScreen(),
      ),
      GoRoute(
        path: '/digital-id',
        builder: (context, state) => const MyDigitalIdScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaceholderScreen(title: 'TravelTrek Dashboard'),
      ),
      GoRoute(
        path: '/sos',
        builder: (context, state) => const PlaceholderScreen(title: 'Emergency SOS'),
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

// Basic placeholder screen to prevent crashes before feature pages are written
class PlaceholderScreen extends ConsumerWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1A3C5E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).performLogout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title Page Placeholder',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('View Digital ID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7A8C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                context.go('/digital-id');
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ref.read(authNotifierProvider.notifier).performLogout();
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
