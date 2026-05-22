import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/domain/models/emergency_contact.dart';
import '../../features/auth/domain/models/tourist_profile.dart';

class HiveService {
  HiveService._();

  static const String _profileBoxName = 'touristProfile';
  static const String _blockchainBoxName = 'blockchainId';
  static const String _tripBoxName = 'active_trip';
  static const String _itineraryBoxName = 'itineraries';
  static const String _settingsBoxName = 'settings';
  static const String _encryptionKeyName = 'hive_encryption_key';
  
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> init() async {
    // 1. Initialize Hive for Flutter
    await Hive.initFlutter();

    // 2. Register manual Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EmergencyContactAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TouristProfileAdapter());
    }

    // 3. Open encrypted box
    await _openEncryptedProfileBox();

    // 4. Open blockchainId box
    await Hive.openBox(_blockchainBoxName);

    // 5. Open tourist feature boxes
    await Hive.openBox(_tripBoxName);
    await Hive.openBox(_itineraryBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  static Future<Box<TouristProfile>> _openEncryptedProfileBox() async {
    if (Hive.isBoxOpen(_profileBoxName)) {
      return Hive.box<TouristProfile>(_profileBoxName);
    }

    // Retrieve or generate key
    List<int> encryptionKey;
    final storedKeyString = await _secureStorage.read(key: _encryptionKeyName);

    if (storedKeyString == null) {
      // Generate random secure key
      final newKey = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64UrlEncode(newKey),
      );
      encryptionKey = newKey;
    } else {
      encryptionKey = base64Url.decode(storedKeyString);
    }

    return await Hive.openBox<TouristProfile>(
      _profileBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  static Box<TouristProfile> get profileBox {
    return Hive.box<TouristProfile>(_profileBoxName);
  }

  static Box get blockchainBox {
    return Hive.box(_blockchainBoxName);
  }

  static Box get tripBox {
    return Hive.box(_tripBoxName);
  }

  static Box get itineraryBox {
    return Hive.box(_itineraryBoxName);
  }

  static Box get settingsBox {
    return Hive.box(_settingsBoxName);
  }

  static Future<void> clearAll() async {
    final box = profileBox;
    await box.clear();
    final blockBox = blockchainBox;
    await blockBox.clear();
    await tripBox.clear();
    await itineraryBox.clear();
    await settingsBox.clear();
  }
}
