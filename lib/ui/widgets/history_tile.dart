import 'package:flutter/material.dart';
import '../../models/station_model.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import 'glass_container.dart';

/// List item / card widget displaying a recently played radio station in a compact format.
/// Features a leading logo, station title, codec info, and handles tap to resume playback.
class HistoryTile extends StatelessWidget {
  final Station station;
  final RadioProvider radioProvider;

  const HistoryTile({
    super.key,
    required this.station,
    required this.radioProvider,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrent =
        radioProvider.currentStation?.stationuuid == station.stationuuid;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () => radioProvider.playStation(station),
        child: GlassContainer(
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          opacity: isCurrent ? 0.12 : 0.04,
          border: isCurrent
              ? Border.all(
                  color: AppTheme.primaryStart.withValues(alpha: 0.3),
                  width: 1.0,
                )
              : null,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  station.favicon,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 36,
                      height: 36,
                      color: AppTheme.surfaceLight,
                      child: const Center(
                        child: Icon(
                          Icons.radio,
                          size: 16,
                          color: Colors.white38,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.codec,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
