import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../domain/models/itinerary_item.dart';
import '../providers/itinerary_provider.dart';

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itineraryProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Itinerary'),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: items.isEmpty
          ? _EmptyItineraryView(onAdd: () => _showAddDialog(context, ref))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isLast = index == items.length - 1;
                return _TimelineNode(
                  item: item,
                  isLast: isLast,
                  onToggle: () => ref.read(itineraryProvider.notifier).toggleComplete(item.id),
                  onDelete: () => ref.read(itineraryProvider.notifier).removeItem(item.id),
                );
              },
            ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final destCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final activitiesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(UiConstants.radiusLG),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Destination', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 16),
                  TextField(
                    controller: destCtrl,
                    decoration: InputDecoration(
                      labelText: 'Destination Name',
                      prefixIcon: const Icon(Icons.place_outlined, color: AppColors.safetyTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Planned Date',
                        prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.safetyTeal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
                      ),
                      child: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: activitiesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Activities (comma-separated)',
                      prefixIcon: const Icon(Icons.local_activity_outlined, color: AppColors.safetyTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.safetyTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(UiConstants.radiusSM)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                        ),
                      ),
                      onPressed: () {
                        if (destCtrl.text.trim().isEmpty) return;
                        final item = ItineraryItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          destination: destCtrl.text.trim(),
                          dateTime: selectedDate,
                          activities: activitiesCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          isCompleted: false,
                          notes: notesCtrl.text.trim(),
                        );
                        ref.read(itineraryProvider.notifier).addItem(item);
                        Navigator.pop(ctx);
                      },
                      child: Text('Add to Itinerary', style: AppTextStyles.buttonText),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------- Timeline Widgets ----------

class _TimelineNode extends StatelessWidget {
  final ItineraryItem item;
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TimelineNode({
    required this.item,
    required this.isLast,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isCompleted ? AppColors.successGreen : AppColors.safetyTeal,
                    border: Border.all(
                      color: item.isCompleted
                          ? AppColors.successGreen.withValues(alpha: 0.3)
                          : AppColors.safetyTeal.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: item.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: item.isCompleted
                          ? AppColors.successGreen.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: item.isCompleted
                    ? Border.all(color: AppColors.successGreen.withValues(alpha: 0.2))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.destination,
                          style: AppTextStyles.cardTitle.copyWith(
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onToggle,
                        child: Icon(
                          item.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          color: item.isCompleted ? AppColors.successGreen : AppColors.mutedText,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM dd yyyy').format(item.dateTime),
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  if (item.activities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.activities.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.safetyTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(a, style: const TextStyle(fontSize: 11, color: AppColors.safetyTeal)),
                        );
                      }).toList(),
                    ),
                  ],
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.notes, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyItineraryView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyItineraryView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 80, color: AppColors.mutedText.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No Itinerary Yet', style: AppTextStyles.screenTitle),
            const SizedBox(height: 8),
            Text(
              'Plan your journey by adding destinations and activities to your timeline.',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Destination'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
