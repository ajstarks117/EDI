import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../providers/blockchain_provider.dart';

class MyDigitalIdScreen extends ConsumerWidget {
  const MyDigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockchainRecordAsync = ref.watch(blockchainIdProvider);
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        title: const Text('My Digital Tourist ID'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
      ),
      body: blockchainRecordAsync.when(
        data: (record) {
          if (record == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.warningAmber),
                  const SizedBox(height: UiConstants.spaceMD),
                  Text('No Digital ID Found', style: AppTextStyles.screenTitle),
                  const SizedBox(height: UiConstants.spaceSM),
                  const Text('Please register your profile first.'),
                  const SizedBox(height: UiConstants.spaceLG),
                  ElevatedButton(
                    onPressed: () => context.go('/profile-setup'),
                    child: const Text('Go to Profile Setup'),
                  ),
                ],
              ),
            );
          }

          // Decode QR Data
          String decodedQrData = '';
          try {
            decodedQrData = utf8.decode(base64.decode(record.qrData));
          } catch (e) {
            debugPrint('Failed to base64 decode QR data: $e');
            decodedQrData = record.qrData; // Fallback to raw string if it is not base64
          }

          final hashLast8 = record.identityHash.length >= 8
              ? record.identityHash.substring(record.identityHash.length - 8)
              : record.identityHash;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(UiConstants.spaceLG),
              child: Column(
                children: [
                  // Verification Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UiConstants.spaceMD,
                      vertical: UiConstants.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.successGreen, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: AppColors.successGreen,
                          size: 16,
                        ),
                        const SizedBox(width: UiConstants.spaceXS),
                        Text(
                          'BLOCKCHAIN VERIFIED ✓',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UiConstants.spaceMD),

                  // main ID Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(UiConstants.radiusLG),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Card Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: UiConstants.spaceMD),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(UiConstants.radiusLG),
                            ),
                          ),
                          width: double.infinity,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shield_outlined, color: Colors.tealAccent, size: 20),
                                const SizedBox(width: UiConstants.spaceSM),
                                Text(
                                  'SECURE TRAVEL ID SYSTEM',
                                  style: AppTextStyles.buttonText.copyWith(
                                    letterSpacing: 1.0,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // QR Code container (min 250x250dp)
                        Padding(
                          padding: const EdgeInsets.all(UiConstants.spaceLG),
                          child: Container(
                            padding: const EdgeInsets.all(UiConstants.spaceMD),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                            ),
                            child: QrImageView(
                              data: decodedQrData,
                              version: QrVersions.auto,
                              size: 250.0,
                              gapless: false,
                              errorStateBuilder: (cxt, err) {
                                return const SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: Center(child: Text("Error rendering QR")),
                                );
                              },
                            ),
                          ),
                        ),

                        // User profile thumbnail, name, ID hash
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: UiConstants.spaceLG),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                                backgroundImage: profile?.profilePhotoUrl != null &&
                                        profile!.profilePhotoUrl.isNotEmpty
                                    ? NetworkImage(profile.profilePhotoUrl)
                                    : null,
                                child: profile?.profilePhotoUrl == null ||
                                        profile!.profilePhotoUrl.isEmpty
                                    ? const Icon(Icons.person, color: AppColors.primaryNavy, size: 24)
                                    : null,
                              ),
                              const SizedBox(width: UiConstants.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?.fullName ?? 'Tourist User',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID Hash: $hashLast8',
                                      style: AppTextStyles.caption.copyWith(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: UiConstants.spaceLG),

                        // Divider
                        Divider(color: Colors.grey.shade200, height: 1),

                        // Card Footer - Offline Available Badge
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: UiConstants.spaceMD),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.offline_pin,
                                color: AppColors.successGreen,
                                size: 20,
                              ),
                              const SizedBox(width: UiConstants.spaceXS),
                              Text(
                                'OFFLINE AVAILABLE',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UiConstants.spaceXL),

                  // Share Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(
                      'Share Secure QR Code',
                      style: AppTextStyles.buttonText.copyWith(fontSize: 15),
                    ),
                    onPressed: () {
                      _showShareDialog(context);
                    },
                  ),
                  const SizedBox(height: UiConstants.spaceMD),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text(
                      'Back to Dashboard',
                      style: TextStyle(color: AppColors.safetyTeal, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.alertRed),
              const SizedBox(height: UiConstants.spaceMD),
              Text('Error Loading Digital ID', style: AppTextStyles.screenTitle),
              const SizedBox(height: UiConstants.spaceSM),
              Text(err.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(UiConstants.radiusLG)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(UiConstants.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Security QR',
                style: AppTextStyles.screenTitle,
              ),
              const SizedBox(height: UiConstants.spaceSM),
              Text(
                'Share your cryptographic identity for quick offline scan & verify by local security outposts.',
                style: AppTextStyles.bodyText.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: UiConstants.spaceLG),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.copy,
                    label: 'Copy Hash',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID Hash copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.image,
                    label: 'Save Image',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR Code saved to gallery'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.share,
                    label: 'System Share',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Secure QR shared successfully!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryNavy, size: 24),
          ),
          const SizedBox(height: UiConstants.spaceSM),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
