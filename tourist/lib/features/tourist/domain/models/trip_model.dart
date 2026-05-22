class TripModel {
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int groupSize;
  final bool isActive;

  const TripModel({
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.groupSize,
    required this.isActive,
  });

  TripModel copyWith({
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? groupSize,
    bool? isActive,
  }) {
    return TripModel(
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      groupSize: groupSize ?? this.groupSize,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'groupSize': groupSize,
      'isActive': isActive,
    };
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      destination: json['destination'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      groupSize: json['groupSize'] as int? ?? 1,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  int get totalDays => endDate.difference(startDate).inDays;

  double get progressPercent {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    final elapsed = now.difference(startDate).inHours;
    final total = endDate.difference(startDate).inHours;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripModel &&
        other.destination == destination &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.groupSize == groupSize &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(destination, startDate, endDate, groupSize, isActive);
}
