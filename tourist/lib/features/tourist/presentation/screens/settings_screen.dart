import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant custom App Bar consistent with the rest of the application
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
                'Settings & Safety',
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. General Preferences Section
                const _SectionHeader(title: 'Preferences'),
                Container(
                  decoration: _groupCardDecoration(),
                  child: Column(
                    children: [
                      // Language selector
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: 'Change interface language',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButton<String>(
                            value: settings.language,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                            style: GoogleFonts.inter(
                              color: AppColors.darkText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'English', child: Text('English')),
                              DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                              DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(settingsProvider.notifier).setLanguage(val);
                              }
                            },
                          ),
                        ),
                      ),
                      _divider(),

                      // Notifications Switch
                      _SettingsToggle(
                        icon: Icons.notifications_rounded,
                        title: 'Safety Alerts & notifications',
                        subtitle: 'Critical area alerts and trip updates',
                        value: settings.notificationsEnabled,
                        onChanged: (val) => ref.read(settingsProvider.notifier).toggleNotifications(val),
                      ),
                      _divider(),

                      // Location Switch
                      _SettingsToggle(
                        icon: Icons.location_on_rounded,
                        title: 'Location Services',
                        subtitle: 'Required for real-time safety maps & SOS features',
                        value: settings.locationEnabled,
                        onChanged: (val) => ref.read(settingsProvider.notifier).toggleLocation(val),
                      ),
                      _divider(),

                      // Dark Mode Switch
                      _SettingsToggle(
                        icon: Icons.dark_mode_rounded,
                        title: 'Dark Mode Theme',
                        subtitle: 'Switch to a sleek dark interface',
                        value: settings.darkModeEnabled,
                        onChanged: (val) => ref.read(settingsProvider.notifier).toggleDarkMode(val),
                      ),
                      _divider(),

                      // Offline Mode Switch
                      _SettingsToggle(
                        icon: Icons.offline_bolt_rounded,
                        title: 'Offline Cache Mode',
                        subtitle: 'Pre-cache safety maps and offline safety tips',
                        value: settings.offlineModeEnabled,
                        onChanged: (val) => ref.read(settingsProvider.notifier).toggleOfflineMode(val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Safety Features Section
                const _SectionHeader(title: 'Safety Mechanisms'),
                Container(
                  decoration: _groupCardDecoration(),
                  child: Column(
                    children: [
                      // Crash Fall Detection Switch
                      _SettingsToggle(
                        icon: Icons.car_crash_rounded,
                        title: 'Crash & Fall Detection',
                        subtitle: 'Auto-broadcast SOS alerts on impact detection',
                        value: settings.crashDetectionEnabled,
                        onChanged: (val) => ref.read(settingsProvider.notifier).toggleCrashDetection(val),
                      ),
                      _divider(),

                      // Backtracking Switch
                      _SettingsToggle(
                        icon: Icons.undo_rounded,
                        title: 'Path Backtracking',
                        subtitle: 'Record route offline to guide you back safely',
                        value: settings.backtrackingEnabled,
                        onChanged: (val) => ref.read(settingsProvider.notifier).toggleBacktracking(val),
                      ),
                      _divider(),

                      // Location Sharing Switch
                      _SettingsToggle(
                        icon: Icons.people_rounded,
                        title: 'Group Location Sharing',
                        subtitle: 'Let verified party members see your coordinates',
                        value: settings.shareLocationWithOthers,
                        onChanged: (val) => ref.read(settingsProvider.notifier).toggleShareLocation(val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Support & Info Section
                const _SectionHeader(title: 'Support & Help'),
                Container(
                  decoration: _groupCardDecoration(),
                  child: Column(
                    children: [
                      // Help
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center & FAQs',
                        subtitle: 'Emergency guidelines and tutorial',
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
                        onTap: () {},
                      ),
                      _divider(),

                      // Privacy Policy
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'Your location data is stored securely',
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
                        onTap: () {},
                      ),
                      _divider(),

                      // About
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About travel-trek',
                        subtitle: 'TravelSure Platform version details',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'v1.0.0 Stable',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // 4. Logout CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutConfirmation(context, ref),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.alertRed, size: 20),
                    label: Text(
                      'Logout Account',
                      style: GoogleFonts.inter(
                        color: AppColors.alertRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.alertRed, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Grouped Card decorations
  BoxDecoration _groupCardDecoration() {
    return BoxDecoration(
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
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF8FAFC),
      indent: 52,
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out of travel-trek? Your emergency records are secured locally on this device.',
          style: GoogleFonts.inter(color: AppColors.darkText, fontSize: 14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiConstants.radiusSM),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).performLogout();
            },
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.safetyTeal,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiConstants.radiusLG),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.safetyTeal.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.safetyTeal, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.safetyTeal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.safetyTeal, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: AppColors.safetyTeal,
            activeTrackColor: AppColors.safetyTeal.withValues(alpha: 0.25),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
