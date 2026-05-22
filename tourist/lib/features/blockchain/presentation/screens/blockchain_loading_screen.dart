import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/ui_constants.dart';
import '../providers/blockchain_provider.dart';

class BlockchainLoadingScreen extends ConsumerStatefulWidget {
  const BlockchainLoadingScreen({super.key});

  @override
  ConsumerState<BlockchainLoadingScreen> createState() => _BlockchainLoadingScreenState();
}

class _BlockchainLoadingScreenState extends ConsumerState<BlockchainLoadingScreen> {
  Timer? _animationTimer;
  String _currentHashVisual = '';
  final Random _random = Random();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  void _startHashAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      final hex = List.generate(64, (_) => '0123456789abcdef'[_random.nextInt(16)]).join();
      setState(() {
        _currentHashVisual = '0x${hex.substring(0, 16)}...${hex.substring(48, 64)}';
      });
    });
  }

  Future<void> _startGeneration() async {
    setState(() {
      _errorMessage = null;
    });
    _startHashAnimation();

    final stopwatch = Stopwatch()..start();

    try {
      // Trigger the blockchain generation
      await ref.read(blockchainNotifierProvider).generateId();

      // Ensure at least 2.5 seconds (2500ms) of animation for visual flair
      final elapsedMs = stopwatch.elapsedMilliseconds;
      if (elapsedMs < 2500) {
        await Future.delayed(Duration(milliseconds: 2500 - elapsedMs));
      }

      if (mounted) {
        context.go('/digital-id');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        _animationTimer?.cancel();
      }
    } finally {
      stopwatch.stop();
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryNavy,
              Color(0xFF0A223A),
              AppColors.safetyTeal,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: UiConstants.spaceLG),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Visual Graphic representing Blockchain/Security
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _errorMessage != null ? Icons.error_outline : Icons.vpn_key_outlined,
                        color: _errorMessage != null ? AppColors.alertRed : Colors.tealAccent,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: UiConstants.spaceXL),
                  if (_errorMessage == null) ...[
                    // Animated loading text
                    Text(
                      'Generating Secure Identity...',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: UiConstants.spaceSM),
                    Text(
                      'Registering cryptographic KYC on-chain',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: UiConstants.spaceXL),
                    // Hash signature animation
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: UiConstants.spaceMD,
                        horizontal: UiConstants.spaceMD,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'SHA-256 SIGNATURE',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: UiConstants.spaceSM),
                          Text(
                            _currentHashVisual,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: UiConstants.spaceXL),
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                        strokeWidth: 3.5,
                      ),
                    ),
                  ] else ...[
                    // Error view
                    Text(
                      'Blockchain Identity Generation Failed',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: UiConstants.spaceSM),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyText.copyWith(
                        color: Colors.redAccent.shade100,
                      ),
                    ),
                    const SizedBox(height: UiConstants.spaceXL),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.safetyTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: UiConstants.spaceMD,
                          horizontal: UiConstants.spaceLG,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text('Retry Generation', style: AppTextStyles.buttonText),
                      onPressed: _startGeneration,
                    ),
                    const SizedBox(height: UiConstants.spaceMD),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        context.go('/');
                      },
                      child: const Text('Back to Home'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
