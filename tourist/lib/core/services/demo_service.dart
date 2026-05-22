import 'package:flutter/foundation.dart';
import '../../features/auth/domain/models/tourist_profile.dart';
import '../../features/auth/domain/models/emergency_contact.dart';
import 'hive_service.dart';

class DemoService {
  static Future<void> seedDemoData() async {
    // 1. Seed Tourist Profile under 'current_profile' if empty
    final profileBox = HiveService.profileBox;
    if (profileBox.isEmpty || !profileBox.containsKey('current_profile')) {
      const contacts = [
        EmergencyContact(
          name: 'Amit Sharma',
          phone: '+919876543210',
          relation: 'Brother',
        ),
        EmergencyContact(
          name: 'Neha Sharma',
          phone: '+919876543211',
          relation: 'Spouse',
        ),
      ];

      const profile = TouristProfile(
        id: 'raj-sharma-12345',
        phoneNumber: '+919876543222',
        fullName: 'Raj Sharma',
        nationality: 'Indian',
        idType: 'Aadhaar',
        idNumber: '1234 5678 9012',
        profilePhotoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
        bloodGroup: 'O+',
        medicalConditions: 'None',
        emergencyContacts: contacts,
        languages: ['English', 'Hindi'],
        regionCode: 'IN',
        isActive: true,
      );

      await profileBox.put('current_profile', profile);
      debugPrint('[DemoService] Seeded tourist profile for Raj Sharma');
    }

    // 2. Seed Blockchain Identity under 'current_record' if empty
    final blockchainBox = HiveService.blockchainBox;
    if (blockchainBox.isEmpty || !blockchainBox.containsKey('current_record')) {
      final mockData = {
        'tourist_id': 'TX-RAJ12345',
        'block_hash': '0x7e8f5c9e2b1d3a4c5f60718293a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2',
        'identity_hash': '8f5c9e2b1d3a4c5f60718293a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a27e',
        'qr_data': 'eyJ0b3VyaXN0X2lkIjoiVFgtUkFKMTIzNDUiLCJibG9ja19oYXNoIjoiMHg3ZThmNWM5ZTJiMWQzYTRjNWY2MDcxODI5M2E0YjVjNmQ3ZThmOWEwYjFjMmQzZTRmNWE2YjdjOGQ5ZTBmMWEyIiwiaWRlbnRpdHlfaGFzaCI6IjhmNWM5ZTJiMWQzYTRjNWY2MDcxODI5M2E0YjVjNmQ3ZThmOWEwYjFjMmQzZTRmNWE2YjdjOGQ5ZTBmMWEyN2UiLCJpc3N1ZWRfYXQiOiIyMDI2LTA1LTIyVDE4OjAwOjAwWiJ9',
        'issued_at': '2026-05-22T18:00:00Z',
      };

      await blockchainBox.put('current_record', mockData);
      debugPrint('[DemoService] Seeded mock blockchain ID');
    }
  }
}
