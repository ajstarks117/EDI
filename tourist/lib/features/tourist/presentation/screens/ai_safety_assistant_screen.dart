import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../ai/ai_state.dart';
import '../../../ai/ai_notifier.dart';
import '../../../sos/presentation/providers/sos_state.dart';
import '../../../safety/services/gps_service.dart';

class AiSafetyAssistantScreen extends ConsumerStatefulWidget {
  const AiSafetyAssistantScreen({super.key});

  @override
  ConsumerState<AiSafetyAssistantScreen> createState() => _AiSafetyAssistantScreenState();
}

class _AiSafetyAssistantScreenState extends ConsumerState<AiSafetyAssistantScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _isDialogShowing = false;
  late AnimationController _micAnimationController;

  static const _quickActions = [
    _QuickAction(label: 'I need first aid', icon: Icons.healing_rounded, type: _QuickActionType.submit),
    _QuickAction(label: 'I am lost', icon: Icons.explore_off_rounded, type: _QuickActionType.preFillLost),
    _QuickAction(label: 'Wildlife nearby', icon: Icons.pets_rounded, type: _QuickActionType.preFillWildlife),
    _QuickAction(label: 'Medical emergency', icon: Icons.local_hospital_rounded, type: _QuickActionType.preFillMedical),
  ];

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _stopListeningAndSetState();
    ref.read(aiStateProvider.notifier).sendMessage(text.trim());
    _inputController.clear();
    _scrollToBottom();
  }

  void _stopListeningAndSetState() {
    if (_isListening) {
      ref.read(aiStateProvider.notifier).stopListening();
      setState(() {
        _isListening = false;
        _micAnimationController.stop();
      });
    }
  }

  void _toggleListening() async {
    final notifier = ref.read(aiStateProvider.notifier);
    if (_isListening) {
      await notifier.stopListening();
      setState(() {
        _isListening = false;
        _micAnimationController.stop();
      });
    } else {
      setState(() {
        _isListening = true;
        _micAnimationController.repeat(reverse: true);
      });
      await notifier.startListening(
        onResult: (text) {
          setState(() {
            _inputController.text = text;
          });
        },
      );
    }
  }

  void _handleQuickAction(_QuickAction action) {
    switch (action.type) {
      case _QuickActionType.submit:
        _send(action.label);
        break;
      case _QuickActionType.preFillLost:
        final pos = ref.read(locationStreamProvider).value;
        final lat = pos?.latitude ?? 18.5204;
        final lng = pos?.longitude ?? 73.8567;
        setState(() {
          _inputController.text = "I am lost. My GPS coordinates are: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}.";
        });
        break;
      case _QuickActionType.preFillWildlife:
        setState(() {
          _inputController.text = "I spotted a wild animal nearby (leopard/bear/monkey). Please guide me on safety.";
        });
        break;
      case _QuickActionType.preFillMedical:
        setState(() {
          _inputController.text = "I have a medical emergency (fever/injured/unconscious). What should I do?";
        });
        break;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSosTriggerDialog(BuildContext context) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.alertRed, size: 28),
              const SizedBox(width: 10),
              Text(
                'SOS Recommended',
                style: AppTextStyles.emergencyText,
              ),
            ],
          ),
          content: const Text(
            'The Safety Assistant has detected that you are in immediate danger. Would you like to activate the SOS beacon system now?',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'I am safe',
                style: TextStyle(color: AppColors.mutedText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(sosStateProvider.notifier).activateSos();
              },
              child: const Text('ACTIVATE SOS'),
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  Widget _buildNetworkStatusChip(String mode) {
    final isOnline = mode == 'online';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 14,
            color: isOnline ? Colors.greenAccent : AppColors.warningAmber,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiStateProvider);
    final messages = aiState.messages;

    // Listen to changes to trigger SOS dialog recommendations
    ref.listen<AiState>(aiStateProvider, (prev, next) {
      _scrollToBottom();
      if (next.messages.isNotEmpty) {
        final lastMsg = next.messages.last;
        if (lastMsg.role == 'assistant' && lastMsg.triggeredSos) {
          _showSosTriggerDialog(context);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_rounded, size: 20),
            SizedBox(width: 8),
            Text('Safety Assistant'),
          ],
        ),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          _buildNetworkStatusChip(aiState.mode),
          IconButton(
            onPressed: () {
              _stopListeningAndSetState();
              ref.read(aiStateProvider.notifier).clearConversation();
            },
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Clear Conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _ChatBubble(message: messages[index]);
              },
            ),
          ),

          // Thinking loading state indicator
          if (aiState.isLoading)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyTeal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Thinking...',
                      style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

          // Quick actions
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickActions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final action = _quickActions[index];
                return ActionChip(
                  avatar: Icon(action.icon, size: 16, color: AppColors.alertRed),
                  label: Text(action.label, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _handleQuickAction(action),
                  backgroundColor: AppColors.alertRed.withValues(alpha: 0.06),
                  side: BorderSide(color: AppColors.alertRed.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Speech-to-text mic button
                  AnimatedBuilder(
                    animation: _micAnimationController,
                    builder: (context, child) {
                      final scale = 1.0 + (_micAnimationController.value * 0.15);
                      return Transform.scale(
                        scale: _isListening ? scale : 1.0,
                        child: IconButton(
                          onPressed: _toggleListening,
                          icon: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: _isListening ? AppColors.alertRed : AppColors.mutedText,
                          ),
                          tooltip: _isListening ? 'Stop Listening' : 'Speak Message',
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening...' : 'Describe your situation...',
                        hintStyle: AppTextStyles.caption.copyWith(
                          color: _isListening ? AppColors.alertRed : AppColors.mutedText,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.safetyTeal),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.offWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(_inputController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryNavy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Chat Bubble Widget ----------

class _ChatBubble extends StatelessWidget {
  final AiMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser && message.intent != null)
              _buildIntentBadge(message.intent!),
            Text(
              message.text,
              style: AppTextStyles.bodyText.copyWith(
                color: isUser ? Colors.white : AppColors.darkText,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentBadge(AiIntent intent) {
    String label;
    Color color;
    switch (intent) {
      case AiIntent.emergency:
        label = '🚨 EMERGENCY';
        color = AppColors.alertRed;
        break;
      case AiIntent.medical:
        label = '🏥 MEDICAL';
        color = AppColors.warningAmber;
        break;
      case AiIntent.navigation:
        label = '🗺️ NAVIGATION';
        color = AppColors.safetyTeal;
        break;
      case AiIntent.information:
        label = 'ℹ️ INFO';
        color = AppColors.mutedText;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ---------- Helper Classes ----------

enum _QuickActionType {
  submit,
  preFillLost,
  preFillWildlife,
  preFillMedical,
}

class _QuickAction {
  final String label;
  final IconData icon;
  final _QuickActionType type;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.type,
  });
}
