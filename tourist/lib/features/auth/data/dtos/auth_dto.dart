import '../../domain/models/emergency_contact.dart';
import '../../domain/models/tourist_profile.dart';

class EmergencyContactDto {
  final String name;
  final String phone;
  final String relation;

  EmergencyContactDto({
    required this.name,
    required this.phone,
    required this.relation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
    };
  }

  factory EmergencyContactDto.fromDomain(EmergencyContact contact) {
    return EmergencyContactDto(
      name: contact.name,
      phone: contact.phone,
      relation: contact.relation,
    );
  }
}

class RegisterRequestDto {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String nationality;
  final String idType;
  final String idNumber;
  final String profilePhotoUrl;
  final String bloodGroup;
  final String medicalConditions;
  final List<EmergencyContactDto> emergencyContacts;
  final List<String> languages;
  final String regionCode;

  RegisterRequestDto({
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
  });

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
    };
  }

  factory RegisterRequestDto.fromDomain(TouristProfile profile) {
    return RegisterRequestDto(
      id: profile.id,
      phoneNumber: profile.phoneNumber,
      fullName: profile.fullName,
      nationality: profile.nationality,
      idType: profile.idType,
      idNumber: profile.idNumber,
      profilePhotoUrl: profile.profilePhotoUrl,
      bloodGroup: profile.bloodGroup,
      medicalConditions: profile.medicalConditions,
      emergencyContacts: profile.emergencyContacts
          .map((c) => EmergencyContactDto.fromDomain(c))
          .toList(),
      languages: profile.languages,
      regionCode: profile.regionCode,
    );
  }
}

class RegisterResponseDto {
  final bool success;
  final String message;

  RegisterResponseDto({
    required this.success,
    required this.message,
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterResponseDto(
      success: json['success'] as bool? ?? (json['profile'] != null),
      message: json['message'] as String? ?? 'Profile registered successfully',
    );
  }
}
