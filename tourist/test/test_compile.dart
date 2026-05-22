// ignore_for_file: avoid_print
import 'package:traveltrek_tourist_app/features/sos/ble_sos_service.dart';

void main() {
  print("Testing compilation of AndroidAdvertiseSettings...");
  // Let's see if we can reference AndroidAdvertiseSettings or if it causes an error
  try {
    // We try to print its type or see if it compiles
    print(AndroidAdvertiseSettings);
  } catch (e) {
    print("Error: $e");
  }
}
