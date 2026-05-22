import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/emergency_contact.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

/// Manages emergency contacts list derived from the authenticated user profile.
/// All mutations go through the auth provider to persist to Hive.
final emergencyContactsProvider = Provider<List<EmergencyContact>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.profile?.emergencyContacts ?? [];
});
