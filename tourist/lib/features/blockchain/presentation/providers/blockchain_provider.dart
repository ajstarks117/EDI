import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/blockchain_record.dart';
import '../../data/services/blockchain_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

enum BlockchainStatus {
  generating,
  verified,
  failed,
  notStarted,
}

final blockchainServiceProvider = Provider<BlockchainService>((ref) {
  return BlockchainService();
});

final blockchainStatusProvider = StateProvider<BlockchainStatus>((ref) {
  final cached = ref.read(blockchainServiceProvider).getCachedRecord();
  return cached != null ? BlockchainStatus.verified : BlockchainStatus.notStarted;
});

final blockchainIdProvider = FutureProvider<BlockchainRecord?>((ref) async {
  final service = ref.watch(blockchainServiceProvider);
  final cached = service.getCachedRecord();
  if (cached != null) {
    // Keep it in sync
    ref.read(blockchainStatusProvider.notifier).state = BlockchainStatus.verified;
    return cached;
  }

  // Auto-generate if missing
  final authState = ref.read(authNotifierProvider);
  if (authState.profile != null) {
    try {
      final notifier = ref.read(blockchainNotifierProvider);
      return await notifier.generateId();
    } catch (e) {
      return null;
    }
  }

  return null;
});

final blockchainNotifierProvider = Provider<BlockchainNotifier>((ref) {
  return BlockchainNotifier(ref);
});

class BlockchainNotifier {
  final Ref _ref;

  BlockchainNotifier(this._ref);

  Future<BlockchainRecord> generateId() async {
    final statusNotifier = _ref.read(blockchainStatusProvider.notifier);
    statusNotifier.state = BlockchainStatus.generating;

    try {
      final authState = _ref.read(authNotifierProvider);
      final profile = authState.profile;
      if (profile == null) {
        throw Exception('No tourist profile found for blockchain registration.');
      }

      final record = await _ref.read(blockchainServiceProvider).generateId(profile);
      statusNotifier.state = BlockchainStatus.verified;
      _ref.invalidate(blockchainIdProvider);
      return record;
    } catch (e) {
      statusNotifier.state = BlockchainStatus.failed;
      rethrow;
    }
  }
}
