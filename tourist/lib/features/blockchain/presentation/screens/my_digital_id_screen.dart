import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6), // Blue
              Color(0xFF8B5CF6), // Purple
              Color(0xFF4F46E5), // Indigo
            ],
          ),
        ),
        child: SafeArea(
          child: blockchainRecordAsync.when(
            data: (record) {
              if (record == null) {
                return _buildErrorState(context, 'No Digital ID Found');
              }

              String decodedQrData = '';
              try {
                decodedQrData = utf8.decode(base64.decode(record.qrData));
              } catch (e) {
                decodedQrData = record.qrData;
              }

              final emergencyContact = profile?.emergencyContacts.isNotEmpty == true 
                  ? profile!.emergencyContacts.first 
                  : null;

              return Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.go('/home'),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'travel-trek',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Digital Tourist ID',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            profile?.fullName ?? 'Tourist User',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${profile?.nationality == 'Indian' ? 'IND' : 'INT'}-${profile?.idNumber ?? 'XXXXXX-XXX'}',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // QR Code Container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: decodedQrData,
                              version: QrVersions.auto,
                              size: 220.0,
                              gapless: false,
                              errorStateBuilder: (cxt, err) => const SizedBox(
                                width: 220,
                                height: 220,
                                child: Center(child: Text("QR Error")),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Details Rows
                          _buildDetailRow('Nationality:', profile?.nationality ?? 'Indian', isPill: true),
                          const SizedBox(height: 16),
                          _buildDetailRow('Valid Until:', '16/04/2026', isBold: true),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Status:', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                                  const SizedBox(width: 4),
                                  Text('Verified', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Emergency Contact Card
                          if (emergencyContact != null)
                            _buildGlassCard(
                              title: 'Emergency Contact',
                              value: emergencyContact.name,
                              subtitle: emergencyContact.phone,
                            )
                          else
                            _buildGlassCard(
                              title: 'Emergency Contact',
                              value: 'Akhilesh ubale',
                              subtitle: '7038620783',
                            ),
                          const SizedBox(height: 16),

                          // Blockchain Security Card
                          _buildGlassCard(
                            title: 'Blockchain Security',
                            value: record.identityHash.length > 20 
                                ? '${record.identityHash.substring(0, 20)}...' 
                                : record.identityHash,
                            isMonospace: true,
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionButton(Icons.account_balance_wallet_outlined, 'Add to Wallet'),
                              _buildActionButton(Icons.ios_share_rounded, 'Share'),
                              _buildActionButton(Icons.download_rounded, 'Download'),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          Text(
                            'Present this QR code to authorities for instant verification.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, stack) => _buildErrorState(context, 'Error Loading Digital ID'),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.go('/home'),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                Text(message, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/profile-setup'),
                  child: const Text('Go to Profile Setup'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPill = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
        if (isPill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white, 
              fontSize: 14, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
      ],
    );
  }

  Widget _buildGlassCard({required String title, required String value, String? subtitle, bool isMonospace = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: isMonospace 
                ? GoogleFonts.spaceMono(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)
                : GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

