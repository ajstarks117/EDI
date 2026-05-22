import '../models/tourist_profile.dart';

abstract class AuthRepository {
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onVerificationFailed,
    required void Function(String verificationId) onTimeout,
  });

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<bool> registerProfile({
    required TouristProfile profile,
  });

  Future<TouristProfile?> getLocalProfile();

  Future<void> saveLocalProfile(TouristProfile profile);

  Future<void> logout();

  bool isUserAuthenticated();

  Future<String?> getFirebaseIdToken();
}
