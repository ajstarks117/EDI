import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/ui_constants.dart';
import '../../features/sos/presentation/providers/sos_state.dart';

/// SOS Floating Action Button — placed in the DashboardShellScreen scaffold.
///
/// • 64dp minimum touch target
/// • Pulsing scale animation (1.0 → 1.08 → 1.0, 1.5s)
/// • On long-press: 3-second progressive hold with circular progress overlay
/// • On completion: transitions SOS to active and navigates to /sos-active
/// • On early release: cancels activation and resets progress
class SosFab extends ConsumerStatefulWidget {
  const SosFab({super.key});

  @override
  ConsumerState<SosFab> createState() => _SosFabState();
}

class _SosFabState extends ConsumerState<SosFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onLongPressStart() {
    ref.read(sosStateProvider.notifier).startActivation();
  }

  void _onLongPressEnd() {
    final sosState = ref.read(sosStateProvider);
    if (sosState.status == SosStatus.activating) {
      // Released before 3 seconds — cancel
      ref.read(sosStateProvider.notifier).cancelActivation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosStateProvider);

    // Navigate to /sos-active when status becomes active
    ref.listen<SosState>(sosStateProvider, (prev, next) {
      if (prev?.status != SosStatus.active && next.isActive) {
        context.go('/sos-active');
      }
    });

    // Don't show if already on the SOS active screen
    if (sosState.isActive) return const SizedBox.shrink();

    final isActivating = sosState.status == SosStatus.activating;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActivating ? 1.0 : _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onLongPressStart: (_) => _onLongPressStart(),
        onLongPressEnd: (_) => _onLongPressEnd(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.alertRed.withValues(alpha: isActivating ? 0.7 : 0.4),
                blurRadius: isActivating ? 24 : 16,
                spreadRadius: isActivating ? 4 : 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.alertRed,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sos_rounded,
                      color: Colors.white,
                      size: isActivating ? 20 : 24,
                    ),
                    if (!isActivating)
                      const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ),

              // Circular progress overlay during hold
              if (isActivating)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: sosState.activationProgress,
                    strokeWidth: 4,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),

              // Countdown text during hold
              if (isActivating)
                Positioned(
                  bottom: 6,
                  child: Text(
                    '${(3 - (sosState.activationProgress * 3)).ceil()}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
