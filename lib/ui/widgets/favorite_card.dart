import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/station_model.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import 'glass_container.dart';

/// Grid item / card widget displaying a favorited radio station.
/// Renders the station favicon, name, country, and responds to tap actions
/// to trigger instant audio playback.
class FavoriteCard extends StatelessWidget {
  final Station station;

  const FavoriteCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    debugPrint("Building FavoriteCard");
    final bool isCurrent = context.select<RadioProvider, bool>(
      (p) => p.currentStation?.stationuuid == station.stationuuid,
    );
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: () => radioProvider.playStation(station),
        child: GlassContainer(
          width: 130,
          padding: const EdgeInsets.all(12),
          opacity: isCurrent ? 0.15 : 0.04,
          border: isCurrent
              ? Border.all(
                  color: AppTheme.primaryStart.withValues(alpha: 0.4),
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
                    color: AppTheme.surfaceLight,
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
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54,
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                station.country.isNotEmpty ? station.country : 'Global',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
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
