import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tourist_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

enum AuthStatus { idle, sending, codeSent, verifying, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? verificationId;
  final String? errorMessage;
  final bool isProfileComplete;
  final bool isLoading;
  final TouristProfile? profile;

  const AuthState({
    required this.status,
    this.verificationId,
    this.errorMessage,
    required this.isProfileComplete,
    required this.isLoading,
    this.profile,
  });

  factory AuthState.initial() {
    return const AuthState(
      status: AuthStatus.idle,
      isProfileComplete: false,
      isLoading: false,
    );
  }

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    String? errorMessage,
    bool? isProfileComplete,
    bool? isLoading,
    TouristProfile? profile,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: errorMessage ?? this.errorMessage,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    // Check initial auth status on start
    _init();
  }

  Future<void> _init() async {
    final isAuthenticated = _repository.isUserAuthenticated();
    if (isAuthenticated) {
      state = state.copyWith(status: AuthStatus.authenticated);
      await checkProfileStatus();
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.sending, isLoading: true, errorMessage: null);

    await _repository.verifyPhone(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        state = state.copyWith(
          status: AuthStatus.codeSent,
          verificationId: verificationId,
          isLoading: false,
        );
      },
      onVerificationFailed: (error) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: error,
          isLoading: false,
        );
      },
      onTimeout: (verificationId) {
        state = state.copyWith(
          verificationId: verificationId,
        );
      },
    );
  }

  Future<void> verifyOtpCode(String smsCode) async {
    state = state.copyWith(status: AuthStatus.verifying, isLoading: true, errorMessage: null);

    // Mock OTP fallback enabled in debug/development mode
    if (kDebugMode && smsCode == '123456') {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
      );
      await checkProfileStatus();
      return;
    }

    final verificationId = state.verificationId;
    if (verificationId == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification ID is missing. Please send OTP again.',
        isLoading: false,
      );
      return;
    }

    try {
      await _repository.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      state = state.copyWith(status: AuthStatus.authenticated, isLoading: false);
      await checkProfileStatus();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> checkProfileStatus() async {
    final profile = await _repository.getLocalProfile();
    if (profile != null) {
      state = state.copyWith(
        isProfileComplete: profile.isComplete,
        profile: profile,
      );
    } else {
      state = state.copyWith(
        isProfileComplete: false,
        profile: null,
      );
    }
  }

  Future<bool> submitProfile(TouristProfile profile) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final success = await _repository.registerProfile(profile: profile);
    if (success) {
      state = state.copyWith(
        isProfileComplete: true,
        isLoading: false,
        profile: profile,
      );
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Registration failed. Could not verify profile details with the server.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> performLogout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = AuthState.initial();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
