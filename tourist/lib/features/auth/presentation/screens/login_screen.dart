import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../shared/widgets/custom_widgets.dart';
import '../providers/auth_state_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
      ref.read(authNotifierProvider.notifier).sendOtp(fullPhoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen to changes in authState to navigate when code is sent or show error dialog/snackbar
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.codeSent && next.verificationId != null) {
        final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
        context.push('/otp?phone=${Uri.encodeComponent(fullPhoneNumber)}');
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
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              ),
            ),
          ),
          // Subtle circular ambient lights
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
                    const Icon(Icons.travel_explore, color: Colors.white, size: 48),
                    const SizedBox(height: UiConstants.spaceSM),
                    Text(
                      'TravelTrek',
                      style: AppTextStyles.appTitle.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: UiConstants.spaceXS),
                    Text(
                      'Safety monitoring & response system',
                      style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: UiConstants.spaceXL),
                    
                    Form(
                      key: _formKey,
                      child: GlassCard(
                        opacity: 0.12,
                        padding: const EdgeInsets.all(UiConstants.spaceLG),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Your Number',
                              style: AppTextStyles.screenTitle.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: UiConstants.spaceSM),
                            Text(
                              'Please enter your phone number to receive a 6-digit verification code.',
                              style: AppTextStyles.bodyText.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                            ),
                            const SizedBox(height: UiConstants.spaceLG),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CountryCodePicker(
                                  selectedCode: _selectedCountryCode,
                                  onChanged: (code) {
                                    setState(() {
                                      _selectedCountryCode = code;
                                    });
                                  },
                                ),
                                const SizedBox(width: UiConstants.spaceSM),
                                Expanded(
                                  child: AppTextField(
                                    controller: _phoneController,
                                    labelText: 'Phone Number',
                                    hintText: '10-digit number',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone_android_outlined,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final cleaned = val.trim();
                                      if (!RegExp(r'^\d{7,15}$').hasMatch(cleaned)) {
                                        return 'Invalid phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: UiConstants.spaceLG),
                            
                            LoadingButton(
                              onPressed: authState.isLoading ? null : _submit,
                              text: 'Send Verification Code',
                              isLoading: authState.isLoading,
                              backgroundColor: Colors.white,
                              textColor: AppColors.primaryNavy,
                            ),
                          ],
                        ),
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
