import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/station_model.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import 'glass_container.dart';

/// List item / card widget displaying a recently played radio station in a compact format.
/// Features a leading logo, station title, codec info, and handles tap to resume playback.
class HistoryTile extends StatelessWidget {
  final Station station;

  const HistoryTile({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    debugPrint("Building HistoryTile");
    final bool isCurrent = context.select<RadioProvider, bool>(
      (p) => p.currentStation?.stationuuid == station.stationuuid,
    );
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);

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
                  color: context.colors.primaryStart.withValues(alpha: 0.3),
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
                      color: context.colors.surfaceLight,
                      child: Center(
                        child: Icon(
                          Icons.radio,
                          size: 16,
                          color: context.colors.textSecondary.withValues(
                            alpha: 0.6,
                          ),
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
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.codec,
                      style: TextStyle(
                        fontSize: 9,
                        color: context.colors.textSecondary,
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
