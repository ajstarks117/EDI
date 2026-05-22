import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../blockchain/presentation/providers/blockchain_provider.dart';
import '../../../blockchain/domain/models/blockchain_record.dart';
import '../providers/trip_provider.dart';
import '../../domain/models/trip_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile;
    final trip = ref.watch(tripProvider);
    final blockchainRecordAsync = ref.watch(blockchainIdProvider);

    // Generate a mock email from their name if profile email is missing
    final emailAddress = profile != null
        ? '${profile.fullName.toLowerCase().replaceAll(' ', '')}@travelsure.org'
        : 'traveler@travelsure.org';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium branded SliverAppBar
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryNavy,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              centerTitle: false,
              title: Text(
                'travel-trek',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -0.5,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFF818CF8), Color(0xFF34D399)],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // extra padding at bottom for bottom buttons
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. User Profile Card
                if (profile != null) ...[
                  _UserProfileHeaderCard(
                    fullName: profile.fullName,
                    nationality: profile.nationality,
                    photoUrl: profile.profilePhotoUrl,
                    onQrTap: () => context.push('/digital-id'),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Trip Status Card (Indigo gradient) or Setup Trip Card
                if (trip != null)
                  _TripStatusCard(trip: trip, nationality: profile?.nationality ?? 'Indian')
                else
                  _SetupTripCard(onSetup: () => _showTripSetupDialog(context, ref)),

                const SizedBox(height: 16),

                // 3. Personal Information Card
                if (profile != null) ...[
                  const _SectionHeader(title: 'Personal Information'),
                  const SizedBox(height: 8),
                  _PersonalInformationCard(
                    email: emailAddress,
                    phoneNumber: profile.phoneNumber,
                    idType: profile.idType,
                    idNumber: profile.idNumber,
                    emergencyContact: profile.emergencyContacts.isNotEmpty
                        ? '${profile.emergencyContacts.first.name} (${profile.emergencyContacts.first.phone})'
                        : 'None Set',
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Trip Details Card
                if (trip != null) ...[
                  const _SectionHeader(title: 'Trip Details'),
                  const SizedBox(height: 8),
                  _TripDetailsCard(trip: trip),
                  const SizedBox(height: 16),
                ],

                // 5. Digital Tourist ID Card (Tappable & Blockchain secure)
                const _SectionHeader(title: 'Digital Tourist ID'),
                const SizedBox(height: 8),
                blockchainRecordAsync.when(
                  data: (record) {
                    if (record == null) {
                      return _PlaceholderDigitalIdCard(
                        onTap: () => context.push('/digital-id'),
                      );
                    }
                    return _SecureDigitalIdCard(
                      record: record,
                      fullName: profile?.fullName ?? 'Tourist User',
                      onTap: () => context.push('/digital-id'),
                    );
                  },
                  loading: () => const _LoadingCard(),
                  error: (err, stack) => _PlaceholderDigitalIdCard(
                    onTap: () => context.push('/digital-id'),
                  ),
                ),

                const SizedBox(height: 16),

                // 6. Safety Score Card (Green card)
                const _SafetyScoreCard(),

                const SizedBox(height: 20),

                // 7. Nearby Emergency Help
                const _SectionHeader(title: 'Nearby Emergency Help'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _HelpCard(
                        icon: Icons.local_police_rounded,
                        title: 'Police Assistance',
                        subtitle: 'Dial 112 / 100',
                        color: const Color(0xFF1565C0),
                        onCall: () => _callNumber('112'),
                        onDirections: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Directions to nearest Police post loaded.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HelpCard(
                        icon: Icons.local_hospital_rounded,
                        title: 'Medical Support',
                        subtitle: 'Dial 102',
                        color: AppColors.successGreen,
                        onCall: () => _callNumber('102'),
                        onDirections: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Directions to nearest Medical Clinic loaded.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 8. Safety Tips Section
                const _SectionHeader(title: 'Personal Safety Tips'),
                const SizedBox(height: 10),
                const _SafetyTipsCarousel(),
              ]),
            ),
          ),
        ],
      ),
      // Sticky bottom emergency buttons row
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/sos'),
                icon: const Icon(Icons.sos_rounded, color: Colors.white, size: 22),
                label: Text('EMERGENCY SOS', style: AppTextStyles.buttonText.copyWith(fontSize: 13, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/digital-id'),
                icon: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
                label: Text('SHOW DIGITAL ID', style: AppTextStyles.buttonText.copyWith(fontSize: 13, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripSetupDialog(BuildContext context, WidgetRef ref) {
    final destController = TextEditingController();
    final groupController = TextEditingController(text: '1');
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 5));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(UiConstants.radiusLG),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Setup Your Trip', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your trip details to get personalized safety monitoring.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: destController,
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      prefixIcon: const Icon(Icons.place_outlined, color: AppColors.safetyTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => startDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                              ),
                            ),
                            child: Text(DateFormat('MMM dd, yy').format(startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => endDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                              ),
                            ),
                            child: Text(DateFormat('MMM dd, yy').format(endDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: groupController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Group Size',
                      prefixIcon: const Icon(Icons.group_outlined, color: AppColors.safetyTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                        ),
                      ),
                      onPressed: () {
                        if (destController.text.trim().isEmpty) return;
                        final trip = TripModel(
                          destination: destController.text.trim(),
                          startDate: startDate,
                          endDate: endDate,
                          groupSize: int.tryParse(groupController.text) ?? 1,
                          isActive: true,
                        );
                        ref.read(tripProvider.notifier).setTrip(trip);
                        Navigator.pop(ctx);
                      },
                      child: Text('Save Trip Details', style: AppTextStyles.buttonText),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------- Sub-widgets & UI Components ----------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: AppColors.primaryNavy,
      ),
    );
  }
}

class _UserProfileHeaderCard extends StatelessWidget {
  final String fullName;
  final String nationality;
  final String? photoUrl;
  final VoidCallback onQrTap;

  const _UserProfileHeaderCard({
    required this.fullName,
    required this.nationality,
    this.photoUrl,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
            backgroundImage: photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null || photoUrl!.isEmpty
                ? Text(
                    initials.isNotEmpty ? initials : 'T',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primaryNavy, fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkText),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Text(
                        'Verified Explorer • $nationality',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.successGreen),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onQrTap,
            icon: const Icon(Icons.qr_code_rounded, color: AppColors.primaryNavy, size: 26),
          ),
          const Icon(Icons.shield_rounded, color: AppColors.safetyTeal, size: 24),
        ],
      ),
    );
  }
}

class _TripStatusCard extends StatelessWidget {
  final TripModel trip;
  final String nationality;
  const _TripStatusCard({required this.trip, required this.nationality});

  @override
  Widget build(BuildContext context) {
    final progress = trip.progressPercent;
    final daysLeft = trip.daysRemaining;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trip Status',
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  'KYC Verified • $nationality',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            trip.destination,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('MMM dd').format(trip.startDate)} — ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.group_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                '${trip.groupSize} Travelers',
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$daysLeft day${daysLeft != 1 ? 's' : ''} remaining',
            style: GoogleFonts.inter(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SetupTripCard extends StatelessWidget {
  final VoidCallback onSetup;
  const _SetupTripCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        border: Border.all(color: AppColors.safetyTeal.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.card_travel_rounded, color: AppColors.safetyTeal, size: 48),
          const SizedBox(height: 12),
          Text('No Active Trip', style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Setup your trip details to get personalized safety monitoring and real-time alerts.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onSetup,
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text('Setup Your Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safetyTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiConstants.radiusMD)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInformationCard extends StatelessWidget {
  final String email;
  final String phoneNumber;
  final String idType;
  final String idNumber;
  final String emergencyContact;

  const _PersonalInformationCard({
    required this.email,
    required this.phoneNumber,
    required this.idType,
    required this.idNumber,
    required this.emergencyContact,
  });

  @override
  Widget build(BuildContext context) {
    // Mask ID number for privacy
    final maskedId = idNumber.length > 4
        ? '${idNumber.substring(0, 2)}***${idNumber.substring(idNumber.length - 2)}'
        : '****';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoFieldTile(icon: Icons.email_outlined, label: 'Email', value: email),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _InfoFieldTile(icon: Icons.phone_outlined, label: 'Mobile Number', value: phoneNumber),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _InfoFieldTile(icon: Icons.badge_outlined, label: 'KYC Document', value: '$idType ($maskedId)'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _InfoFieldTile(icon: Icons.contact_emergency_outlined, label: 'Emergency Contact', value: emergencyContact),
        ],
      ),
    );
  }
}

class _InfoFieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoFieldTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.safetyTeal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripDetailsCard extends StatelessWidget {
  final TripModel trip;
  const _TripDetailsCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('MMMM dd, yyyy').format(trip.startDate);
    final end = DateFormat('MMMM dd, yyyy').format(trip.endDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_rounded, color: AppColors.safetyTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Destination',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
              ),
              const Spacer(),
              Text(
                trip.destination,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Date', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 3),
                  Text(start, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('End Date', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 3),
                  Text(end, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Party Size', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText)),
              Text(
                '${trip.groupSize} Traveler${trip.groupSize > 1 ? 's' : ''}',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecureDigitalIdCard extends StatelessWidget {
  final BlockchainRecord record;
  final String fullName;
  final VoidCallback onTap;

  const _SecureDigitalIdCard({
    required this.record,
    required this.fullName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String decodedQrData = '';
    try {
      decodedQrData = utf8.decode(base64.decode(record.qrData));
    } catch (e) {
      decodedQrData = record.qrData;
    }

    final displayHash = record.identityHash.length > 12
        ? '${record.identityHash.substring(0, 6)}...${record.identityHash.substring(record.identityHash.length - 6)}'
        : record.identityHash;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(UiConstants.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background logo
            const Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.shield_rounded, size: 100, color: Colors.white),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.offline_pin, color: Colors.tealAccent, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'SECURE ID',
                            style: GoogleFonts.outfit(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Blockchain Secured Hash',
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayHash,
                        style: GoogleFonts.spaceMono(color: Colors.tealAccent.withValues(alpha: 0.9), fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Text(
                          '✓ VERIFIED ON-CHAIN',
                          style: GoogleFonts.inter(color: Colors.tealAccent, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Custom rendered mini QR Code preview
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                  ),
                  child: QrImageView(
                    data: decodedQrData,
                    version: QrVersions.auto,
                    size: 72.0,
                    gapless: false,
                    errorStateBuilder: (cxt, err) => const SizedBox(width: 72, height: 72),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderDigitalIdCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PlaceholderDigitalIdCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.amberAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'DIGITAL EXPLORER ID',
                        style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Setup Identity Key',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate security QR & cryptographic blockchain registry.',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SafetyScoreCard extends StatelessWidget {
  const _SafetyScoreCard();

  @override
  Widget build(BuildContext context) {
    const score = 82;
    const color = AppColors.successGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 5,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '$score',
                  style: GoogleFonts.inter(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Score',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkText),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your current area is secure. Network signal is strong. Stay aware of weather updates.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onCall;
  final VoidCallback onDirections;

  const _HelpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onCall,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 13, color: Colors.white),
                  label: const Text('Call Now', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDirections,
                  icon: Icon(Icons.directions_rounded, size: 13, color: color),
                  label: Text('Directions', style: TextStyle(fontSize: 11, color: color)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetyTipsCarousel extends StatelessWidget {
  const _SafetyTipsCarousel();

  @override
  Widget build(BuildContext context) {
    final tips = [
      const _TipItem(
        icon: Icons.offline_pin_outlined,
        title: 'Offline Security ID',
        desc: 'Keep your digital ID downloaded to show to security checkpoints in zero-signal zones.',
      ),
      const _TipItem(
        icon: Icons.map_outlined,
        title: 'Explore Safety Areas',
        desc: 'Review green safe routes and yellow weather alerts on the Live Map before wandering.',
      ),
      const _TipItem(
        icon: Icons.battery_charging_full_rounded,
        title: 'Battery Conservation',
        desc: 'Charge your device above 50% and activate Offline Mode in settings to preserve battery life.',
      ),
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tips.length,
        itemBuilder: (ctx, idx) {
          final tip = tips[idx];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(UiConstants.radiusLG),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(tip.icon, color: AppColors.safetyTeal, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    tip.desc,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedText, height: 1.3),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TipItem {
  final IconData icon;
  final String title;
  final String desc;
  const _TipItem({required this.icon, required this.title, required this.desc});
}
