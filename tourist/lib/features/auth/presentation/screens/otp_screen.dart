import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../shared/widgets/custom_widgets.dart';
import '../providers/auth_state_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _resendTimeoutSeconds = 30;
  
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  Timer? _timer;
  int _secondsRemaining = _resendTimeoutSeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _resendTimeoutSeconds;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _getOtpCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _submitOtp() {
    final code = _getOtpCode();
    if (code.length == 6) {
      ref.read(authNotifierProvider.notifier).verifyOtpCode(code);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 6-digit code.'),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  void _resendCode() {
    if (!_canResend) return;
    ref.read(authNotifierProvider.notifier).sendOtp(widget.phoneNumber);
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code resent.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _onTextChanged(int index, String value) {
    if (value.isNotEmpty) {
      // If we typed a character, move to next node
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last box filled, auto submit if all are filled
        _focusNodes[index].unfocus();
        if (_getOtpCode().length == 6) {
          _submitOtp();
        }
      }
    }
  }

  void _onKeyAction(int index, KeyEvent event) {
    // Detect backspace
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.backspace && 
        _controllers[index].text.isEmpty && 
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        if (next.isProfileComplete) {
          context.go('/');
        } else {
          context.go('/profile-setup');
        }
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching WelcomeScreen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A1C71), Color(0xFFD76D77)],
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: UiConstants.spaceLG),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(height: UiConstants.spaceSM),
                    const Icon(Icons.security, color: Colors.white, size: 48),
                    const SizedBox(height: UiConstants.spaceSM),
                    Text(
                      'Enter Verification Code',
                      style: AppTextStyles.appTitle.copyWith(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: UiConstants.spaceXS),
                    Text(
                      'Sent to ${widget.phoneNumber}',
                      style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: UiConstants.spaceXL),
                    
                    GlassCard(
                      opacity: 0.12,
                      padding: const EdgeInsets.all(UiConstants.spaceLG),
                      child: Column(
                        children: [
                          // 6-digit grid layout
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 42,
                                height: 50,
                                child: KeyboardListener(
                                  focusNode: FocusNode(), // Dummy focus node for listener key capture
                                  onKeyEvent: (event) => _onKeyAction(index, event),
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    style: AppTextStyles.screenTitle.copyWith(color: Colors.white),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      contentPadding: EdgeInsets.zero,
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 2),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 3),
                                      ),
                                    ),
                                    onChanged: (val) => _onTextChanged(index, val),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: UiConstants.spaceXL),
                          
                          LoadingButton(
                            onPressed: authState.isLoading ? null : _submitOtp,
                            text: 'Verify & Proceed',
                            isLoading: authState.isLoading,
                            backgroundColor: Colors.white,
                            textColor: AppColors.primaryNavy,
                          ),
                          const SizedBox(height: UiConstants.spaceLG),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _canResend 
                                    ? "Didn't receive code? " 
                                    : "Resend code in ${_secondsRemaining}s",
                                style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                              ),
                              if (_canResend)
                                TextButton(
                                  onPressed: _resendCode,
                                  child: Text(
                                    'Resend',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white, 
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          // Inform developer of mock fallback
                          const SizedBox(height: UiConstants.spaceSM),
                          Text(
                            'Debug mode: Use 123456 as code to bypass',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: UiConstants.spaceXL),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
