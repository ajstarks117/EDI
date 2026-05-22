import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/emergency_contact.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/tourist_profile.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:traveltrek_tourist_app/features/auth/presentation/providers/auth_state_provider.dart';

// Mock Auth Repository for isolated unit testing
class MockAuthRepository implements AuthRepository {
  bool authenticated = false;
  TouristProfile? localProfile;
  bool throwOnRegister = false;
  String? lastVerifiedPhone;

  @override
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onVerificationFailed,
    required void Function(String verificationId) onTimeout,
  }) async {
    lastVerifiedPhone = phoneNumber;
    await Future.delayed(const Duration(milliseconds: 5));
    if (phoneNumber.startsWith('+91000')) {
      onVerificationFailed('Invalid Mock Number');
    } else {
      onCodeSent('mock_verification_id_123', null);
    }
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (smsCode == '123456') {
      authenticated = true;
    } else {
      throw Exception('Invalid OTP');
    }
  }

  @override
  Future<bool> registerProfile({required TouristProfile profile}) async {
    if (throwOnRegister) return false;
    localProfile = profile;
    return true;
  }

  @override
  Future<TouristProfile?> getLocalProfile() async {
    return localProfile;
  }

  @override
  Future<void> saveLocalProfile(TouristProfile profile) async {
    localProfile = profile;
  }

  @override
  Future<void> logout() async {
    authenticated = false;
    localProfile = null;
  }

  @override
  bool isUserAuthenticated() => authenticated;

  @override
  Future<String?> getFirebaseIdToken() async => 'mock_token';
}

void main() {
  group('Auth Domain Models & Serialization Tests', () {
    test('EmergencyContact equality and copyWith', () {
      const contact1 = EmergencyContact(name: 'Alice', phone: '1234567890', relation: 'Spouse');
      const contact2 = EmergencyContact(name: 'Alice', phone: '1234567890', relation: 'Spouse');
      final contact3 = contact1.copyWith(name: 'Bob');

      expect(contact1, equals(contact2));
      expect(contact1, isNot(equals(contact3)));
      expect(contact3.name, equals('Bob'));
      expect(contact3.phone, equals('1234567890'));
    });

    test('EmergencyContact json serialization/deserialization', () {
      const contact = EmergencyContact(name: 'Alice', phone: '1234567890', relation: 'Spouse');
      final json = contact.toJson();
      final fromJson = EmergencyContact.fromJson(json);

      expect(fromJson, equals(contact));
    });

    test('TouristProfile isComplete validator', () {
      const incompleteProfile = TouristProfile(
        id: 'u1',
        phoneNumber: '+919999999999',
        fullName: '',
        nationality: 'Indian',
        idType: 'Aadhaar',
        idNumber: '1234',
        profilePhotoUrl: '',
        bloodGroup: 'O+',
        medicalConditions: '',
        emergencyContacts: [
          EmergencyContact(name: 'Alice', phone: '1234567890', relation: 'Spouse'),
        ],
        languages: ['English'],
        regionCode: 'IN',
        isActive: true,
      );

      expect(incompleteProfile.isComplete, isFalse); // Empty name, < 2 contacts

      final completeProfile = incompleteProfile.copyWith(
        fullName: 'John Doe',
        emergencyContacts: const [
          EmergencyContact(name: 'Alice', phone: '1234567890', relation: 'Spouse'),
          EmergencyContact(name: 'Bob', phone: '0987654321', relation: 'Brother'),
        ],
      );

      expect(completeProfile.isComplete, isTrue);
    });

    test('TouristProfile json serialization/deserialization', () {
      const profile = TouristProfile(
        id: 'u1',
        phoneNumber: '+919999999999',
        fullName: 'John Doe',
        nationality: 'Indian',
        idType: 'Aadhaar',
        idNumber: '1234-5678-9012',
        profilePhotoUrl: 'https://photo.url',
        bloodGroup: 'O+',
        medicalConditions: 'None',
        emergencyContacts: [
          EmergencyContact(name: 'Alice', phone: '1234567890', relation: 'Spouse'),
          EmergencyContact(name: 'Bob', phone: '0987654321', relation: 'Brother'),
        ],
        languages: ['English', 'Hindi'],
        regionCode: 'IN',
        isActive: true,
      );

      final json = profile.toJson();
      final fromJson = TouristProfile.fromJson(json);

      expect(fromJson, equals(profile));
    });
  });

  group('AuthNotifier State Flow Tests', () {
    late MockAuthRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial State is Idle', () {
      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.idle));
      expect(state.isLoading, isFalse);
      expect(state.isProfileComplete, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('sendOtp success transitions state to codeSent', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      
      final future = notifier.sendOtp('+919876543210');
      
      // Should show loading while verifying
      expect(container.read(authNotifierProvider).status, equals(AuthStatus.sending));
      expect(container.read(authNotifierProvider).isLoading, isTrue);

      await future;

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.codeSent));
      expect(state.isLoading, isFalse);
      expect(state.verificationId, equals('mock_verification_id_123'));
      expect(mockRepository.lastVerifiedPhone, equals('+919876543210'));
    });

    test('sendOtp failure transitions state to error', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      
      await notifier.sendOtp('+910000000000');

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.error));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, equals('Invalid Mock Number'));
    });

    test('verifyOtpCode success transitions state to authenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      
      // 1. Send OTP
      await notifier.sendOtp('+919876543210');
      
      // 2. Verify OTP
      await notifier.verifyOtpCode('123456');

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.isLoading, isFalse);
      expect(state.isProfileComplete, isFalse);
    });

    test('submitProfile success updates local cache and isProfileComplete', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      
      const profile = TouristProfile(
        id: 'u1',
        phoneNumber: '+919876543210',
        fullName: 'John Doe',
        nationality: 'Indian',
        idType: 'Aadhaar',
        idNumber: '1234',
        profilePhotoUrl: '',
        bloodGroup: 'O+',
        medicalConditions: '',
        emergencyContacts: [
          EmergencyContact(name: 'Alice', phone: '1234567890', relation: 'Spouse'),
          EmergencyContact(name: 'Bob', phone: '0987654321', relation: 'Brother'),
        ],
        languages: ['English'],
        regionCode: 'IN',
        isActive: true,
      );

      final success = await notifier.submitProfile(profile);

      expect(success, isTrue);
      
      final state = container.read(authNotifierProvider);
      expect(state.isProfileComplete, isTrue);
      expect(state.profile, equals(profile));
      expect(mockRepository.localProfile, equals(profile));
    });

    test('logout resets auth notifier state', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      
      // Authenticate & complete profile
      await notifier.sendOtp('+919876543210');
      await notifier.verifyOtpCode('123456');
      
      // Logout
      await notifier.performLogout();

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.idle));
      expect(state.isProfileComplete, isFalse);
      expect(state.profile, isNull);
      expect(mockRepository.authenticated, isFalse);
      expect(mockRepository.localProfile, isNull);
    });
  });
}
