import 'package:flutter/material.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import 'glass_container.dart';

/// Bottom sheet widget allowing users to select or cancel a sleep timer duration.
/// Schedules automatic playback stoppage based on chosen presets.
class SleepTimerSheet extends StatelessWidget {
  final RadioProvider radioProvider;

  const SleepTimerSheet({super.key, required this.radioProvider});

  @override
  Widget build(BuildContext context) {
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
            'SLEEP TIMER',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Automatically stop playback after duration',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _timerOption(context, 'Cancel', null, radioProvider),
              _timerOption(
                context,
                '5m',
                const Duration(minutes: 5),
                radioProvider,
              ),
              _timerOption(
                context,
                '15m',
                const Duration(minutes: 15),
                radioProvider,
              ),
              _timerOption(
                context,
                '30m',
                const Duration(minutes: 30),
                radioProvider,
              ),
              _timerOption(
                context,
                '45m',
                const Duration(minutes: 45),
                radioProvider,
              ),
              _timerOption(
                context,
                '60m',
                const Duration(minutes: 60),
                radioProvider,
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
    RadioProvider provider,
  ) {
    return InkWell(
      onTap: () {
        if (duration == null) {
          provider.cancelSleepTimer();
        } else {
          provider.startSleepTimer(duration);
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
