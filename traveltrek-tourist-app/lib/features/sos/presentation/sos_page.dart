import 'package:flutter/material.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  bool _isSosActive = false;

  void _triggerSos() {
    setState(() {
      _isSosActive = true;
    });

    // SOS Flow implementation:
    // 1. Get GPS coordinates
    // 2. Broadcast via WebSocket/Internet
    // 3. Fallback to SMS if offline
    // 4. Fallback to BLE mesh advertising
    // 5. Activate local Audio Siren
  }

  void _cancelSos() {
    setState(() {
      _isSosActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isSosActive ? const Color(0xFF1C0A0A) : Colors.black,
      appBar: AppBar(
        title: const Text('EMERGENCY SOS'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSosActive) ...[
              const Icon(Icons.warning, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'SOS ACTIVE',
                style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Attempting broadcast via internet, SMS, and Bluetooth...'),
              const SizedBox(height: 40),
            ],
            GestureDetector(
              onTap: _isSosActive ? _cancelSos : _triggerSos,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSosActive ? Colors.red : const Color(0xFFB71C1C),
                  boxShadow: [
                    BoxShadow(
                      color: _isSosActive ? Colors.red.withOpacity(0.5) : Colors.red.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    _isSosActive ? 'CANCEL' : 'SOS',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
