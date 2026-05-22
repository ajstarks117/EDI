import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/hive_service.dart';

class SettingsState {
  final String language;
  final bool notificationsEnabled;
  final bool locationEnabled;
  final bool offlineModeEnabled;
  final bool darkModeEnabled;
  final bool crashDetectionEnabled;
  final bool backtrackingEnabled;
  final bool shareLocationWithOthers;

  const SettingsState({
    this.language = 'English',
    this.notificationsEnabled = true,
    this.locationEnabled = true,
    this.offlineModeEnabled = false,
    this.darkModeEnabled = false,
    this.crashDetectionEnabled = true,
    this.backtrackingEnabled = false,
    this.shareLocationWithOthers = false,
  });

  SettingsState copyWith({
    String? language,
    bool? notificationsEnabled,
    bool? locationEnabled,
    bool? offlineModeEnabled,
    bool? darkModeEnabled,
    bool? crashDetectionEnabled,
    bool? backtrackingEnabled,
    bool? shareLocationWithOthers,
  }) {
    return SettingsState(
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      crashDetectionEnabled: crashDetectionEnabled ?? this.crashDetectionEnabled,
      backtrackingEnabled: backtrackingEnabled ?? this.backtrackingEnabled,
      shareLocationWithOthers: shareLocationWithOthers ?? this.shareLocationWithOthers,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'notificationsEnabled': notificationsEnabled,
        'locationEnabled': locationEnabled,
        'offlineModeEnabled': offlineModeEnabled,
        'darkModeEnabled': darkModeEnabled,
        'crashDetectionEnabled': crashDetectionEnabled,
        'backtrackingEnabled': backtrackingEnabled,
        'shareLocationWithOthers': shareLocationWithOthers,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      language: json['language'] as String? ?? 'English',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      locationEnabled: json['locationEnabled'] as bool? ?? true,
      offlineModeEnabled: json['offlineModeEnabled'] as bool? ?? false,
      darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
      crashDetectionEnabled: json['crashDetectionEnabled'] as bool? ?? true,
      backtrackingEnabled: json['backtrackingEnabled'] as bool? ?? false,
      shareLocationWithOthers: json['shareLocationWithOthers'] as bool? ?? false,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = HiveService.settingsBox;
    final jsonStr = box.get('prefs') as String?;
    if (jsonStr != null) {
      try {
        state = SettingsState.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      } catch (_) {
        // keep defaults
      }
    }
  }

  Future<void> _persist() async {
    final box = HiveService.settingsBox;
    await box.put('prefs', jsonEncode(state.toJson()));
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _persist();
  }

  Future<void> toggleNotifications(bool val) async {
    state = state.copyWith(notificationsEnabled: val);
    await _persist();
  }

  Future<void> toggleLocation(bool val) async {
    state = state.copyWith(locationEnabled: val);
    await _persist();
  }

  Future<void> toggleOfflineMode(bool val) async {
    state = state.copyWith(offlineModeEnabled: val);
    await _persist();
  }

  Future<void> toggleDarkMode(bool val) async {
    state = state.copyWith(darkModeEnabled: val);
    await _persist();
  }

  Future<void> toggleCrashDetection(bool val) async {
    state = state.copyWith(crashDetectionEnabled: val);
    await _persist();
  }

  Future<void> toggleBacktracking(bool val) async {
    state = state.copyWith(backtrackingEnabled: val);
    await _persist();
  }

  Future<void> toggleShareLocation(bool val) async {
    state = state.copyWith(shareLocationWithOthers: val);
    await _persist();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
