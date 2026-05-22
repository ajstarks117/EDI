class ItineraryItem {
  final String id;
  final String destination;
  final DateTime dateTime;
  final List<String> activities;
  final bool isCompleted;
  final String notes;

  const ItineraryItem({
    required this.id,
    required this.destination,
    required this.dateTime,
    required this.activities,
    required this.isCompleted,
    required this.notes,
  });

  ItineraryItem copyWith({
    String? id,
    String? destination,
    DateTime? dateTime,
    List<String>? activities,
    bool? isCompleted,
    String? notes,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      dateTime: dateTime ?? this.dateTime,
      activities: activities ?? this.activities,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'dateTime': dateTime.toIso8601String(),
      'activities': activities,
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ?? DateTime.now(),
      activities: (json['activities'] as List<dynamic>?)?.cast<String>() ?? [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItineraryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
