import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/station_model.dart';
import '../../providers/playback_provider.dart';
import '../../core/theme/app_theme.dart';
import 'glass_container.dart';

/// Grid item / card widget displaying a favorited radio station.
/// Renders the station favicon, name, country, and responds to tap actions
/// to trigger instant audio playback.
class FavoriteCard extends ConsumerWidget {
  final Station station;

  const FavoriteCard({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("Building FavoriteCard");
    final bool isCurrent = ref.watch(
      playbackProvider.select(
        (p) => p.currentStation?.stationuuid == station.stationuuid,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: () => ref.read(playbackProvider.notifier).playStation(station),
        child: GlassContainer(
          width: 130,
          padding: const EdgeInsets.all(12),
          opacity: isCurrent ? 0.15 : 0.04,
          border: isCurrent
              ? Border.all(
                  color: context.colors.primaryStart.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.colors.surfaceLight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      station.favicon,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            station.name.isNotEmpty
                                ? station.name[0].toUpperCase()
                                : 'R',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                station.name.trim(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                station.country.isNotEmpty ? station.country : 'Global',
                style: TextStyle(
                  fontSize: 10,
                  color: context.colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
