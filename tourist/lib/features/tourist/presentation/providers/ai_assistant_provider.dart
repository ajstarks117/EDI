import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';

class _HandbookEntry {
  final String title;
  final List<String> tags;
  final String text;

  const _HandbookEntry({
    required this.title,
    required this.tags,
    required this.text,
  });
}

class AiAssistantNotifier extends StateNotifier<List<ChatMessage>> {
  AiAssistantNotifier() : super([
    ChatMessage(
      id: 'welcome',
      text: 'Hello! I\'m your TravelSure Safety Assistant. I can help you with emergency guidance, safety tips, first aid, and navigation support — fully offline.\n\nTap a quick action below or describe your situation.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  int _msgCounter = 0;

  static const List<_HandbookEntry> _handbook = [
    _HandbookEntry(
      title: 'Lost / Navigation Help',
      tags: ['lost', 'where', 'location', 'gps', 'navigate', 'map', 'find', 'path', 'direction'],
      text: '🧭 **Stay Calm — You\'re Not Alone**\n\n'
          '1. **Stay put**: Do not wander further into unfamiliar territory.\n'
          '2. **Check the Map**: Open the Map tab to view your active GPS coordinates.\n'
          '3. **Identify Landmarks**: Look around for hills, fort walls, rivers, or marked trails.\n'
          '4. **Helpline**: Call the Tourist Helpline immediately at **1363**.\n'
          '5. **Zero Signal?** Go to the Map screen and slide up the Safety Features to enable Backtracking or locate safe shelter.',
    ),
    _HandbookEntry(
      title: 'Medical Emergency',
      tags: ['medical', 'hospital', 'doctor', 'blood', 'ambulance', 'clinic', 'first aid', 'emergency'],
      text: '🏥 **Medical Emergency Protocol**\n\n'
          '1. **Call 102 or 112**: Contact Ambulance or National Emergency lines immediately.\n'
          '2. **Control Bleeding**: Apply firm, direct pressure to the wound with a clean cloth.\n'
          '3. **Do Not Move**: Unless they are in immediate hazard, do not move an injured person.\n'
          '4. **Pin Location**: Use the Map screen to identify your precise location to guide paramedics.\n'
          '5. **Airway Clear**: Ensure the victim is breathing and their airway is clear.',
    ),
    _HandbookEntry(
      title: 'Snake & Animal Bites',
      tags: ['snake', 'bite', 'venom', 'cobra', 'poison', 'viper', 'scorpion', 'dog', 'animal'],
      text: '🐍 **Snake / Animal Bite First Aid**\n\n'
          '1. **Keep Still**: Keep the victim calm and still. Movement accelerates venom spread.\n'
          '2. **Bite Level**: Keep the bite area BELOW the level of the heart.\n'
          '3. **Cleanse**: Wash the area gently with soap and water.\n'
          '4. **Loose Bandage**: Wrap the area in a clean, loose bandage. Do NOT cut the wound or try to suck out venom.\n'
          '5. **Anti-Venom**: Rush to the nearest hospital. Call **102** for emergency transport.',
    ),
    _HandbookEntry(
      title: 'Fractures & Sprains',
      tags: ['fracture', 'bone', 'sprain', 'break', 'arm', 'leg', 'ankle', 'wrist', 'fall', 'joint'],
      text: '🦴 **Fractures & Sprains Guide**\n\n'
          '1. **Immobilize**: Do not try to snap the bone back or move the limb.\n'
          '2. **Splinting**: Support the limb with a splint (use rigid sticks or cardboard tied with cloth).\n'
          '3. **Ice**: Apply ice wrapped in a towel to reduce swelling.\n'
          '4. **Elevate**: Elevate the injured area if it doesn\'t cause severe pain.\n'
          '5. **Transport**: Seek medical help to get an X-ray.',
    ),
    _HandbookEntry(
      title: 'CPR / Choking',
      tags: ['cpr', 'breath', 'breathe', 'pulse', 'heart', 'choke', 'choking', 'unconscious', 'faint'],
      text: '🫁 **Emergency CPR & Choking Guide**\n\n'
          '• **Choking (Heimlich Maneuver)**:\nStand behind the person, wrap arms around their waist, make a fist and press hard inward and upward just above their navel.\n\n'
          '• **CPR (Adult)**:\n1. Place hands on center of chest.\n2. Push hard and fast: 100 to 120 compressions per minute (staying alive beat).\n3. Give 2 rescue breaths after every 30 compressions if trained.',
    ),
    _HandbookEntry(
      title: 'Wild Animal Encounters',
      tags: ['animal', 'wild', 'leopard', 'bear', 'monkey', 'boar', 'forest', 'attack', 'tiger'],
      text: '🐆 **Wild Animal Safety (Leopards & Bears)**\n\n'
          '1. **Do Not Run**: Running triggers the predator chase instinct. Never turn your back.\n'
          '2. **Eye Contact**: Back away slowly. Avoid prolonged aggressive staring but watch the animal.\n'
          '3. **Appear Large**: Raise your arms, open your jacket, and stand tall.\n'
          '4. **Make Noise**: Shout loudly, wave sticks, or clap hands to intimidate the animal.\n'
          '5. **Secure Food**: Monkeys and bears are attracted to food. Keep rations sealed in your pack.',
    ),
    _HandbookEntry(
      title: 'Severe Weather / Storms',
      tags: ['weather', 'storm', 'rain', 'flood', 'lightning', 'thunder', 'monsoon', 'landslide', 'mulshi'],
      text: '⛈️ **Severe Weather & Storm Safety**\n\n'
          '1. **Find Shelter**: Get inside a building or hard-topped vehicle immediately. Avoid tall trees.\n'
          '2. **Flash Floods**: Move to higher ground instantly if near streams or river beds.\n'
          '3. **Lightning**: Stay away from metal objects, open fields, and water bodies.\n'
          '4. **Landslides**: Watch for falling debris, cracking slopes, or sudden muddy water flow.\n'
          '5. **NDRF Hotline**: Call Disaster Response at **1078** or Emergency at **112**.',
    ),
    _HandbookEntry(
      title: 'No Network / Signal',
      tags: ['signal', 'network', 'connection', 'offline', 'coverage', 'cell', 'wifi', 'towers'],
      text: '📡 **No Network Recovery Protocol**\n\n'
          '1. **Elevation**: Move to higher ground or a clear clearing for better cell tower line-of-sight.\n'
          '2. **Re-Scan**: Toggle Airplane Mode ON for 10 seconds, then OFF to force your phone to seek network towers.\n'
          '3. **Offline Tools**: Your Digital ID and Travel Trek Emergency features are cached and work fully offline.\n'
          '4. **Bluetooth Mesh**: If lost near other trekkers, trigger the SOS screen to advertise alert beacons via Bluetooth.',
    ),
    _HandbookEntry(
      title: 'Fire Emergency',
      tags: ['fire', 'smoke', 'burn', 'flame', 'forest fire', 'extinguisher'],
      text: '🔥 **Fire Emergency Protocol**\n\n'
          '1. **Call 101**: Notify the Fire Department immediately.\n'
          '2. **Stay Low**: Crawl under smoke to breathe cleaner air near the floor.\n'
          '3. **Cover Face**: Cover your mouth and nose with a damp cloth.\n'
          '4. **Escape**: Avoid elevators; use stairs or emergency exits. Head to open fields.\n'
          '5. **Stop, Drop, Roll**: If clothing catches fire, drop to the ground and roll over and over.',
    ),
  ];

  void sendMessage(String text) {
    _msgCounter++;
    final userMsg = ChatMessage(
      id: 'user_$_msgCounter',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    // Generate offline matching response
    Future.delayed(const Duration(milliseconds: 400), () {
      _msgCounter++;
      final response = _generateResponse(text);
      final aiMsg = ChatMessage(
        id: 'ai_$_msgCounter',
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, aiMsg];
    });
  }

  String _generateResponse(String input) {
    final words = input.toLowerCase().split(RegExp(r'[\s,\.\-_!?()\"#\$%&*\+=<>/:;]+'));
    
    _HandbookEntry? bestMatch;
    double highestScore = 0.0;

    for (final entry in _handbook) {
      double score = 0.0;
      for (final word in words) {
        if (word.isEmpty || word.length < 3) continue;
        if (entry.tags.contains(word)) {
          score += 2.0; // Tag match has high weight
        }
        if (entry.title.toLowerCase().contains(word)) {
          score += 1.0; // Title match has medium weight
        }
        if (entry.text.toLowerCase().contains(word)) {
          score += 0.5; // Text match has small weight
        }
      }
      if (score > highestScore) {
        highestScore = score;
        bestMatch = entry;
      }
    }

    if (highestScore >= 1.5 && bestMatch != null) {
      return bestMatch.text;
    }

    // Default fallback if no clear match
    return '🛡️ **Safety Assistant (Offline Mode)**\n\n'
        'I am running locally on your device without internet. I couldn\'t match your query exactly. Try describing your issue using keywords like:\n\n'
        '• 🐍 **"snake bite"** or **"dog bite"**\n'
        '• 🦴 **"bone fracture"** or **"sprain"**\n'
        '• 🧭 **"I am lost"** or **"directions"**\n'
        '• 🫁 **"CPR instruction"** or **"choking"**\n'
        '• ⛈️ **"storm safety"** or **"landslide"**\n'
        '• 🐆 **"leopard attack"** or **"wild monkey"**\n'
        '• 📡 **"no network"** or **"offline map"**\n'
        '• 🔥 **"fire emergency"**\n\n'
        'Or tap one of the safety action chips below!';
  }

  void clearConversation() {
    _msgCounter = 0;
    state = [
      ChatMessage(
        id: 'welcome',
        text: 'Conversation cleared. How can I help you stay safe?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, List<ChatMessage>>((ref) {
  return AiAssistantNotifier();
});
