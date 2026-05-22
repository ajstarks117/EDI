import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/hive_service.dart';
import '../../domain/models/itinerary_item.dart';

class ItineraryNotifier extends StateNotifier<List<ItineraryItem>> {
  ItineraryNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = HiveService.itineraryBox;
    final jsonStr = box.get('items') as String?;
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        state = list.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _persist() async {
    final box = HiveService.itineraryBox;
    await box.put('items', jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> addItem(ItineraryItem item) async {
    state = [...state, item];
    await _persist();
  }

  Future<void> updateItem(ItineraryItem updated) async {
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
    await _persist();
  }

  Future<void> removeItem(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _persist();
  }

  Future<void> toggleComplete(String id) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isCompleted: !item.isCompleted) else item,
    ];
    await _persist();
  }
}

final itineraryProvider = StateNotifierProvider<ItineraryNotifier, List<ItineraryItem>>((ref) {
  return ItineraryNotifier();
});
