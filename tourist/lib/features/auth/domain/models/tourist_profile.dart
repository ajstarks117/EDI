import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'emergency_contact.dart';

class TouristProfile {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String nationality;
  final String idType;
  final String idNumber;
  final String profilePhotoUrl;
  final String bloodGroup;
  final String medicalConditions;
  final List<EmergencyContact> emergencyContacts;
  final List<String> languages;
  final String regionCode;
  final bool isActive;

  const TouristProfile({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.nationality,
    required this.idType,
    required this.idNumber,
    required this.profilePhotoUrl,
    required this.bloodGroup,
    required this.medicalConditions,
    required this.emergencyContacts,
    required this.languages,
    required this.regionCode,
    required this.isActive,
  });

  TouristProfile copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    String? nationality,
    String? idType,
    String? idNumber,
    String? profilePhotoUrl,
    String? bloodGroup,
    String? medicalConditions,
    List<EmergencyContact>? emergencyContacts,
    List<String>? languages,
    String? regionCode,
    bool? isActive,
  }) {
    return TouristProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      nationality: nationality ?? this.nationality,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      languages: languages ?? this.languages,
      regionCode: regionCode ?? this.regionCode,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'nationality': nationality,
      'idType': idType,
      'idNumber': idNumber,
      'profilePhotoUrl': profilePhotoUrl,
      'bloodGroup': bloodGroup,
      'medicalConditions': medicalConditions,
      'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
      'languages': languages,
      'regionCode': regionCode,
      'isActive': isActive,
    };
  }

  factory TouristProfile.fromJson(Map<String, dynamic> json) {
    return TouristProfile(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      idType: json['idType'] as String? ?? '',
      idNumber: json['idNumber'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      medicalConditions: json['medicalConditions'] as String? ?? '',
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      regionCode: json['regionCode'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  bool get isComplete {
    return fullName.isNotEmpty &&
        emergencyContacts.length >= 2 &&
        idType.isNotEmpty &&
        idNumber.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TouristProfile &&
        other.id == id &&
        other.phoneNumber == phoneNumber &&
        other.fullName == fullName &&
        other.nationality == nationality &&
        other.idType == idType &&
        other.idNumber == idNumber &&
        other.profilePhotoUrl == profilePhotoUrl &&
        other.bloodGroup == bloodGroup &&
        other.medicalConditions == medicalConditions &&
        listEquals(other.emergencyContacts, emergencyContacts) &&
        listEquals(other.languages, languages) &&
        other.regionCode == regionCode &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      phoneNumber,
      fullName,
      nationality,
      idType,
      idNumber,
      profilePhotoUrl,
      bloodGroup,
      medicalConditions,
      Object.hashAll(emergencyContacts),
      Object.hashAll(languages),
      regionCode,
      isActive,
    );
  }

  @override
  String toString() {
    return 'TouristProfile(id: $id, phoneNumber: $phoneNumber, fullName: $fullName, nationality: $nationality, idType: $idType, idNumber: $idNumber, profilePhotoUrl: $profilePhotoUrl, bloodGroup: $bloodGroup, medicalConditions: $medicalConditions, emergencyContacts: $emergencyContacts, languages: $languages, regionCode: $regionCode, isActive: $isActive)';
  }
}

class TouristProfileAdapter extends TypeAdapter<TouristProfile> {
  @override
  final int typeId = 1;

  @override
  TouristProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TouristProfile(
      id: fields[0] as String? ?? '',
      phoneNumber: fields[1] as String? ?? '',
      fullName: fields[2] as String? ?? '',
      nationality: fields[3] as String? ?? '',
      idType: fields[4] as String? ?? '',
      idNumber: fields[5] as String? ?? '',
      profilePhotoUrl: fields[6] as String? ?? '',
      bloodGroup: fields[7] as String? ?? '',
      medicalConditions: fields[8] as String? ?? '',
      emergencyContacts: (fields[9] as List<dynamic>?)?.cast<EmergencyContact>() ?? [],
      languages: (fields[10] as List<dynamic>?)?.cast<String>() ?? [],
      regionCode: fields[11] as String? ?? '',
      isActive: fields[12] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, TouristProfile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.fullName)
      ..writeByte(3)
      ..write(obj.nationality)
      ..writeByte(4)
      ..write(obj.idType)
      ..writeByte(5)
      ..write(obj.idNumber)
      ..writeByte(6)
      ..write(obj.profilePhotoUrl)
      ..writeByte(7)
      ..write(obj.bloodGroup)
      ..writeByte(8)
      ..write(obj.medicalConditions)
      ..writeByte(9)
      ..write(obj.emergencyContacts)
      ..writeByte(10)
      ..write(obj.languages)
      ..writeByte(11)
      ..write(obj.regionCode)
      ..writeByte(12)
      ..write(obj.isActive);
  }
}
