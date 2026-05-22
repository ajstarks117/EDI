import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/hive_service.dart';
import '../../domain/models/trip_model.dart';

class TripNotifier extends StateNotifier<TripModel?> {
  TripNotifier() : super(null) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = HiveService.tripBox;
    final jsonStr = box.get('current_trip') as String?;
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = TripModel.fromJson(map);
      } catch (_) {
        state = null;
      }
    }
  }

  Future<void> setTrip(TripModel trip) async {
    state = trip;
    final box = HiveService.tripBox;
    await box.put('current_trip', jsonEncode(trip.toJson()));
  }

  Future<void> clearTrip() async {
    state = null;
    final box = HiveService.tripBox;
    await box.delete('current_trip');
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripModel?>((ref) {
  return TripNotifier();
});
