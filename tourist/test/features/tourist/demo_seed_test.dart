import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/tourist_profile.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/emergency_contact.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:traveltrek_tourist_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:traveltrek_tourist_app/core/services/demo_service.dart';

class HiveBackedMockAuthRepository implements AuthRepository {
  bool authenticated = false;

  @override
  Future<TouristProfile?> getLocalProfile() async {
    final box = Hive.box<TouristProfile>('touristProfile');
    return box.get('current_profile');
  }

  @override
  Future<void> saveLocalProfile(TouristProfile profile) async {
    final box = Hive.box<TouristProfile>('touristProfile');
    await box.put('current_profile', profile);
  }

  @override
  bool isUserAuthenticated() => authenticated;

  @override
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onVerificationFailed,
    required void Function(String verificationId) onTimeout,
  }) async {}

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {}

  @override
  Future<bool> registerProfile({required TouristProfile profile}) async {
    await saveLocalProfile(profile);
    return true;
  }

  @override
  Future<void> logout() async {
    authenticated = false;
    final box = Hive.box<TouristProfile>('touristProfile');
    await box.clear();
  }

  @override
  Future<String?> getFirebaseIdToken() async => 'mock_token';
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory('${Directory.current.path}/build/test_hive_demo_seed');
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    tempDir.createSync(recursive: true);
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EmergencyContactAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TouristProfileAdapter());
    }

    await Hive.openBox<TouristProfile>('touristProfile');
    await Hive.openBox('blockchainId');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('DemoService seeds profile and blockchain data correctly when empty', () async {
    final profileBox = Hive.box<TouristProfile>('touristProfile');
    final blockchainBox = Hive.box('blockchainId');

    expect(profileBox.isEmpty, isTrue);
    expect(blockchainBox.isEmpty, isTrue);

    await DemoService.seedDemoData();

    expect(profileBox.isNotEmpty, isTrue);
    expect(blockchainBox.isNotEmpty, isTrue);

    final profile = profileBox.get('current_profile');
    expect(profile, isNotNull);
    expect(profile!.fullName, equals('Raj Sharma'));
    expect(profile.emergencyContacts.length, equals(2));

    final record = blockchainBox.get('current_record');
    expect(record, isNotNull);
    expect(record['tourist_id'], equals('TX-RAJ12345'));
  });

  test('DemoService does not overwrite existing profile and blockchain data', () async {
    final profileBox = Hive.box<TouristProfile>('touristProfile');
    final blockchainBox = Hive.box('blockchainId');

    const existingProfile = TouristProfile(
      id: 'existing-id',
      phoneNumber: '+919999999999',
      fullName: 'Existing User',
      nationality: 'Indian',
      idType: 'Passport',
      idNumber: 'P12345',
      profilePhotoUrl: '',
      bloodGroup: 'A+',
      medicalConditions: 'None',
      emergencyContacts: [],
      languages: ['English'],
      regionCode: 'IN',
      isActive: true,
    );

    await profileBox.put('current_profile', existingProfile);

    final existingRecord = {
      'tourist_id': 'TX-EXISTING',
      'block_hash': '0xhash',
    };
    await blockchainBox.put('current_record', existingRecord);

    await DemoService.seedDemoData();

    final profile = profileBox.get('current_profile');
    expect(profile!.fullName, equals('Existing User'));

    final record = blockchainBox.get('current_record');
    expect(record['tourist_id'], equals('TX-EXISTING'));
  });

  test('AuthNotifier automatically logs in when profile is cached locally', () async {
    // 1. Seed demo data
    await DemoService.seedDemoData();

    // 2. Initialize provider container with Hive backed mock repository
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(HiveBackedMockAuthRepository()),
      ],
    );

    // Trigger notifier creation and start _init()
    container.read(authNotifierProvider.notifier);

    // Wait for the async _init() to finish
    await Future.delayed(const Duration(milliseconds: 50));

    // 3. Read Auth State
    final state = container.read(authNotifierProvider);

    // 4. Assert bypass authentication was successful
    expect(state.status, equals(AuthStatus.authenticated));
    expect(state.isProfileComplete, isTrue);
    expect(state.profile, isNotNull);
    expect(state.profile!.fullName, equals('Raj Sharma'));

    container.dispose();
  });
}
