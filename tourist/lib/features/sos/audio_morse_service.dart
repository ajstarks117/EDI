import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioMorseService {
  AudioPlayer? _player;
  Timer? _loopTimer;
  File? _wavFile;

  Future<void> init() async {
    if (_wavFile == null) {
      final wavBytes = generateMorseSosWav();
      final tempDir = await getTemporaryDirectory();
      _wavFile = File('${tempDir.path}/sos_morse_siren.wav');
      await _wavFile!.writeAsBytes(wavBytes);
    }
  }

  Future<void> startSiren() async {
    await init();
    _player ??= AudioPlayer();

    // Play immediately
    await _playOnce();

    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _playOnce();
    });
  }

  Future<void> _playOnce() async {
    if (_wavFile != null && _player != null) {
      try {
        await _player!.stop();
        await _player!.play(DeviceFileSource(_wavFile!.path));
      } catch (e) {
        // Log error and handle gracefully
        // e.g. on simulators/hosts where audio hardware is absent
      }
    }
  }

  Future<void> stopSiren() async {
    _loopTimer?.cancel();
    _loopTimer = null;
    if (_player != null) {
      try {
        await _player!.stop();
        await _player!.dispose();
      } catch (_) {}
      _player = null;
    }
  }
}

class _SoundPart {
  final bool isSound;
  final int durationMs;
  _SoundPart(this.isSound, this.durationMs);
}

Uint8List generateMorseSosWav() {
  const sampleRate = 8000;
  const frequency = 1000.0;

  // Timing in milliseconds
  const dotDuration = 150;
  const dashDuration = 450;
  const elementGap = 150;
  const characterGap = 450;

  final sequence = [
    _SoundPart(true, dotDuration),
    _SoundPart(false, elementGap),
    _SoundPart(true, dotDuration),
    _SoundPart(false, elementGap),
    _SoundPart(true, dotDuration),

    _SoundPart(false, characterGap),

    _SoundPart(true, dashDuration),
    _SoundPart(false, elementGap),
    _SoundPart(true, dashDuration),
    _SoundPart(false, elementGap),
    _SoundPart(true, dashDuration),

    _SoundPart(false, characterGap),

    _SoundPart(true, dotDuration),
    _SoundPart(false, elementGap),
    _SoundPart(true, dotDuration),
    _SoundPart(false, elementGap),
    _SoundPart(true, dotDuration),
  ];

  int totalSamples = 0;
  for (var part in sequence) {
    totalSamples += (part.durationMs * sampleRate) ~/ 1000;
  }

  final pcmData = Uint8List(totalSamples);
  int currentSample = 0;

  for (var part in sequence) {
    final samples = (part.durationMs * sampleRate) ~/ 1000;
    for (int i = 0; i < samples; i++) {
      if (part.isSound) {
        final t = (currentSample + i) / sampleRate;
        final val = (128 + 60 * math.sin(2 * math.pi * frequency * t)).round();
        pcmData[currentSample + i] = val.clamp(0, 255);
      } else {
        pcmData[currentSample + i] = 128; // Silence for 8-bit PCM (unsigned)
      }
    }
    currentSample += samples;
  }

  final header = ByteData(44);
  // "RIFF"
  header.setUint8(0, 0x52); // R
  header.setUint8(1, 0x49); // I
  header.setUint8(2, 0x46); // F
  header.setUint8(3, 0x46); // F
  header.setUint32(4, 36 + totalSamples, Endian.little);
  // "WAVE"
  header.setUint8(8, 0x57);  // W
  header.setUint8(9, 0x41);  // A
  header.setUint8(10, 0x56); // V
  header.setUint8(11, 0x45); // E
  // "fmt "
  header.setUint8(12, 0x66); // f
  header.setUint8(13, 0x6D); // m
  header.setUint8(14, 0x74); // t
  header.setUint8(15, 0x20); // 
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate, Endian.little);
  header.setUint16(32, 1, Endian.little);
  header.setUint16(34, 8, Endian.little);
  // "data"
  header.setUint8(36, 0x64); // d
  header.setUint8(37, 0x61); // a
  header.setUint8(38, 0x74); // t
  header.setUint8(39, 0x61); // a
  header.setUint32(40, totalSamples, Endian.little);

  final wavBytes = BytesBuilder();
  wavBytes.add(header.buffer.asUint8List());
  wavBytes.add(pcmData);
  return wavBytes.toBytes();
}
