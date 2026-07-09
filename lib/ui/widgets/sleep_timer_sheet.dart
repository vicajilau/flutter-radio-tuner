import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/playback_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/extensions/context_l10n.dart';
import 'glass_container.dart';

/// Bottom sheet widget allowing users to select or cancel a sleep timer duration.
/// Schedules automatic playback stoppage based on chosen presets.
class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playbackProvider.notifier);

    return GlassContainer(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      opacity: 0.18,
      borderOpacity: 0.25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.textPrimary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.sleepTimer,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.sleepTimerSubtitle,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _timerOption(context, context.l10n.cancel, null, notifier),
              _timerOption(context, '5m', const Duration(minutes: 5), notifier),
              _timerOption(
                context,
                '15m',
                const Duration(minutes: 15),
                notifier,
              ),
              _timerOption(
                context,
                '30m',
                const Duration(minutes: 30),
                notifier,
              ),
              _timerOption(
                context,
                '45m',
                const Duration(minutes: 45),
                notifier,
              ),
              _timerOption(
                context,
                '60m',
                const Duration(minutes: 60),
                notifier,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerOption(
    BuildContext context,
    String label,
    Duration? duration,
    PlaybackNotifier notifier,
  ) {
    return InkWell(
      onTap: () {
        if (duration == null) {
          notifier.cancelSleepTimer();
        } else {
          notifier.startSleepTimer(duration);
        }
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.textPrimary.withValues(alpha: 0.04),
          border: Border.all(
            color: context.colors.textPrimary.withValues(alpha: 0.06),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
