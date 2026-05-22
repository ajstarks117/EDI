import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/tourist_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dtos/auth_dto.dart';
import '../services/auth_service.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/constants/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _profileCacheKey = 'current_profile';
  static const String _tokenKey = 'firebase_id_token';

  AuthRepositoryImpl({
    AuthService? authService,
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _authService = authService ?? AuthService(),
        _dio = dio ?? Dio(BaseOptions(baseUrl: AppConstants.backendBaseUrl)),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onVerificationFailed,
    required void Function(String verificationId) onTimeout,
  }) async {
    try {
      await _authService.verifyPhone(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          // Automatic verification in some cases (e.g. instant verification or instant retrieval)
          try {
            await _authService.signInWithCredential(credential);
            final token = await _authService.getIdToken();
            if (token != null) {
              await _secureStorage.write(key: _tokenKey, value: token);
            }
          } catch (e) {
            onVerificationFailed(e.toString());
          }
        },
        verificationFailed: (firebase.FirebaseAuthException exception) {
          onVerificationFailed(exception.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onTimeout(verificationId);
        },
      );
    } catch (e) {
      onVerificationFailed(e.toString());
    }
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = firebase.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _authService.signInWithCredential(credential);
    final token = await _authService.getIdToken();
    if (token != null) {
      await _secureStorage.write(key: _tokenKey, value: token);
    }
  }

  @override
  Future<bool> registerProfile({
    required TouristProfile profile,
  }) async {
    try {
      final requestDto = RegisterRequestDto.fromDomain(profile);
      
      // POST profile data to /auth/register
      final response = await _dio.post(
        '/auth/register',
        data: requestDto.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseDto = RegisterResponseDto.fromJson(response.data as Map<String, dynamic>);
        if (responseDto.success) {
          // Cache the profile locally in the encrypted box
          await saveLocalProfile(profile);
          return true;
        }
      }
      return false;
    } catch (e) {
      // In debug/demo mode, we can cache locally as fallback if backend is offline
      // We will allow registration locally if the call fails with connection error in debug
      assert(() {
        saveLocalProfile(profile);
        return true;
      }());
      return false;
    }
  }

  @override
  Future<TouristProfile?> getLocalProfile() async {
    try {
      final box = HiveService.profileBox;
      return box.get(_profileCacheKey);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveLocalProfile(TouristProfile profile) async {
    final box = HiveService.profileBox;
    await box.put(_profileCacheKey, profile);
  }

  @override
  Future<void> logout() async {
    await _authService.signOut();
    await _secureStorage.delete(key: _tokenKey);
    await HiveService.clearAll();
  }

  @override
  bool isUserAuthenticated() {
    return _authService.currentUser != null;
  }

  @override
  Future<String?> getFirebaseIdToken() async {
    return await _secureStorage.read(key: _tokenKey) ?? await _authService.getIdToken();
  }
}
