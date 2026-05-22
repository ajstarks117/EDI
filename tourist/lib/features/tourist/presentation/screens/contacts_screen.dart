import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../auth/domain/models/emergency_contact.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../providers/contacts_provider.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(emergencyContactsProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Branded SliverAppBar matching the premium dashboard look
          SliverAppBar(
            expandedHeight: 90,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryNavy,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              centerTitle: false,
              title: Text(
                'Emergency Hub',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Emergency Services Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Helplines (India)',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap to call immediately',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Critical Helpline Panel (National Emergency 112)
                const _CriticalEmergencyServiceCard(
                  icon: Icons.emergency_rounded,
                  title: 'National Emergency Service',
                  number: '112',
                  subtitle: 'Police · Ambulance · Fire · Disasters',
                  gradients: [Color(0xFFDC2626), Color(0xFF991B1B)],
                ),
                const SizedBox(height: 12),

                // Helplines Grid System (Interactive 2-column Layout)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: const [
                    _EmergencyServiceGridCard(
                      icon: Icons.local_police_rounded,
                      title: 'Police Force',
                      number: '100',
                      subtitle: 'Law enforcement',
                      gradients: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                    ),
                    _EmergencyServiceGridCard(
                      icon: Icons.local_hospital_rounded,
                      title: 'Medical / Ambulance',
                      number: '102',
                      subtitle: 'Medical transport',
                      gradients: [Color(0xFF059669), Color(0xFF064E3B)],
                    ),
                    _EmergencyServiceGridCard(
                      icon: Icons.fire_truck_rounded,
                      title: 'Fire Department',
                      number: '101',
                      subtitle: 'Fire & rescue',
                      gradients: [Color(0xFFEA580C), Color(0xFF7C2D12)],
                    ),
                    _EmergencyServiceGridCard(
                      icon: Icons.woman_rounded,
                      title: 'Women Helpline',
                      number: '1091',
                      subtitle: 'Safety & support',
                      gradients: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                    ),
                    _EmergencyServiceGridCard(
                      icon: Icons.travel_explore_rounded,
                      title: 'Tourist Support',
                      number: '1363',
                      subtitle: '24/7 travel desk',
                      gradients: [Color(0xFF0D9488), Color(0xFF115E59)],
                    ),
                    _EmergencyServiceGridCard(
                      icon: Icons.storm_rounded,
                      title: 'Disaster Cell',
                      number: '1078',
                      subtitle: 'NDRF management',
                      gradients: [Color(0xFF4F46E5), Color(0xFF312E81)],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Personal Contacts Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Personal Contacts',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAddContactDialog(context, ref),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.safetyTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppColors.safetyTeal.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_add_rounded, color: AppColors.safetyTeal, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Add Contact',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.safetyTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Personal Contacts List
                if (contacts.isEmpty)
                  _EmptyContactsCard(onAdd: () => _showAddContactDialog(context, ref))
                else
                  ...contacts.asMap().entries.map((entry) {
                    return _PersonalContactCard(
                      contact: entry.value,
                      onCall: () => _dialNumber(entry.value.phone),
                      onDelete: () => _showDeleteConfirmation(context, ref, entry.key, entry.value.name),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dialNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, int index, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Contact', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove $name from your emergency contacts?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiConstants.radiusLG)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final authState = ref.read(authNotifierProvider);
              final profile = authState.profile;
              if (profile == null) return;

              final updated = List<EmergencyContact>.from(profile.emergencyContacts);
              updated.removeAt(index);
              final updatedProfile = profile.copyWith(emergencyContacts: updated);
              ref.read(authNotifierProvider.notifier).submitProfile(updatedProfile);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name removed successfully.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Remove', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(UiConstants.radiusLG),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add Emergency Contact',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This person will be alerted automatically in case of SOS triggers.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
                ),
                const SizedBox(height: 20),

                // Name Input
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: GoogleFonts.inter(color: AppColors.mutedText, fontSize: 13),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.safetyTeal),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.safetyTeal, width: 2),
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Relationship Input
                TextFormField(
                  controller: relationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Relationship (e.g. Spouse, Friend)',
                    labelStyle: GoogleFonts.inter(color: AppColors.mutedText, fontSize: 13),
                    prefixIcon: const Icon(Icons.family_restroom_outlined, color: AppColors.safetyTeal),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.safetyTeal, width: 2),
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter relationship';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone Input
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: GoogleFonts.inter(color: AppColors.mutedText, fontSize: 13),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.safetyTeal),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.safetyTeal, width: 2),
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a phone number';
                    }
                    final phoneExp = RegExp(r'^\+?[0-9]{8,15}$');
                    if (!phoneExp.hasMatch(value.trim())) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                      ),
                    ),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      final authState = ref.read(authNotifierProvider);
                      final profile = authState.profile;
                      if (profile == null) return;

                      final newContact = EmergencyContact(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        relation: relationCtrl.text.trim(),
                      );
                      final updated = profile.copyWith(
                        emergencyContacts: [...profile.emergencyContacts, newContact],
                      );
                      ref.read(authNotifierProvider.notifier).submitProfile(updated);
                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${newContact.name} added to emergency contacts.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(
                      'Save Contact',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- Premium Custom Cards ----------

class _CriticalEmergencyServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String number;
  final String subtitle;
  final List<Color> gradients;

  const _CriticalEmergencyServiceCard({
    required this.icon,
    required this.title,
    required this.number,
    required this.subtitle,
    required this.gradients,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: gradients[0].withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final uri = Uri(scheme: 'tel', path: number);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          borderRadius: BorderRadius.circular(UiConstants.radiusLG),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Pulse Animation effect on Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(icon, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call_rounded, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        number,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyServiceGridCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String number;
  final String subtitle;
  final List<Color> gradients;

  const _EmergencyServiceGridCard({
    required this.icon,
    required this.title,
    required this.number,
    required this.subtitle,
    required this.gradients,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: gradients[0].withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final uri = Uri(scheme: 'tel', path: number);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          borderRadius: BorderRadius.circular(UiConstants.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call_rounded, color: gradients[0], size: 10),
                          const SizedBox(width: 4),
                          Text(
                            number,
                            style: GoogleFonts.outfit(
                              color: gradients[0],
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 9.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  const _PersonalContactCard({
    required this.contact,
    required this.onCall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Branded CircleAvatar
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.safetyTeal, Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.safetyTeal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          contact.relation,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.safetyTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          contact.phone,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Dynamic actions buttons
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCall,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_rounded, color: AppColors.successGreen, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.alertRed.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyContactsCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyContactsCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, color: Colors.grey.shade400, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'No emergency contacts added',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText),
          ),
          const SizedBox(height: 6),
          Text(
            'Add family members or friends who should be contacted in emergencies.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
            label: Text('Add Emergency Contact', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
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
