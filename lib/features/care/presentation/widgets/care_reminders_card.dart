import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/care/application/care_reminders_provider.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:aquagrow_mobile/features/care/presentation/widgets/care_reminder_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card displaying recurring pod care reminders with completion progress.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class CareRemindersCard extends ConsumerWidget {
  /// Creates a [CareRemindersCard].
  const CareRemindersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ag;
    final reminders = ref.watch(careRemindersProvider);
    final completedCount = reminders.where((r) => r.isCompleted).length;
    final totalCount = reminders.length;

    return Container(
      padding: const EdgeInsets.all(AgSpace.s16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.all(AgRadius.r20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    color: colors.brand,
                    size: 22,
                  ),
                  const SizedBox(width: AgSpace.s8),
                  Text(
                    'Care reminders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgSpace.s8,
                  vertical: AgSpace.s4,
                ),
                decoration: BoxDecoration(
                  color: completedCount == totalCount && totalCount > 0
                      ? colors.brandSurface
                      : colors.subtle,
                  borderRadius: AgRadius.all(AgRadius.pill),
                ),
                child: Text(
                  '$completedCount of $totalCount done',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: completedCount == totalCount && totalCount > 0
                            ? colors.text
                            : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AgSpace.s12),
          if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AgSpace.s16),
              child: Center(
                child: Text(
                  'No care reminders scheduled',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return CareReminderItemTile(
                  reminder: reminder,
                  onToggle: (_) => _handleToggle(context, ref, reminder),
                );
              },
            ),
        ],
      ),
    );
  }

  void _handleToggle(
    BuildContext context,
    WidgetRef ref,
    CareReminder reminder,
  ) {
    final willComplete = !reminder.isCompleted;
    ref.read(careRemindersProvider.notifier).toggle(reminder.id);

    if (willComplete) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      final colors = context.ag;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: colors.brand,
                size: 18,
              ),
              const SizedBox(width: AgSpace.s8),
              Expanded(
                child: Text(
                  'Completed "${reminder.title}" · Due in ${reminder.intervalDays}d',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: colors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AgRadius.all(AgRadius.r16),
            side: BorderSide(color: colors.border),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
