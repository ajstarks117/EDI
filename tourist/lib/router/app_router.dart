import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderScreen(title: 'TravelTrek Dashboard'),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const PlaceholderScreen(title: 'Authentication'),
    ),
    GoRoute(
      path: '/sos',
      builder: (context, state) => const PlaceholderScreen(title: 'Emergency SOS'),
    ),
  ],
);

// Basic placeholder screen to prevent crashes before feature pages are written
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title Page Placeholder',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
