import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/station_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/playback_provider.dart';
import '../../core/theme/app_theme.dart';
import 'glass_container.dart';

/// List tile widget representing a radio station in list views.
/// Renders favicon, title, tags, country code, votes count,
/// favorite toggle button, and a mini active visualizer bar if playing.
class StationTile extends ConsumerWidget {
  final Station station;

  const StationTile({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCurrent = ref.watch(
      playbackProvider.select(
        (p) => p.currentStation?.stationuuid == station.stationuuid,
      ),
    );
    final bool isPlaying = ref.watch(
      playbackProvider.select(
        (p) =>
            p.currentStation?.stationuuid == station.stationuuid && p.isPlaying,
      ),
    );
    final bool isBuffering = ref.watch(
      playbackProvider.select(
        (p) =>
            p.currentStation?.stationuuid == station.stationuuid &&
            p.isBuffering,
      ),
    );
    final bool isFavorited = ref.watch(
      favoritesProvider.select(
        (s) => s.favorites.any((f) => f.stationuuid == station.stationuuid),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => ref.read(playbackProvider.notifier).playStation(station),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          opacity: isCurrent ? 0.12 : 0.04,
          borderOpacity: isCurrent ? 0.25 : 0.08,
          border: isCurrent
              ? Border.all(
                  color: context.colors.primaryStart.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
          child: Row(
            children: [
              // Station Logo / Placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      context.colors.surfaceLight,
                      isCurrent
                          ? context.colors.primaryStart.withValues(alpha: 0.3)
                          : context.colors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isCurrent
                        ? context.colors.primaryStart.withValues(alpha: 0.3)
                        : context.colors.textPrimary.withValues(alpha: 0.05),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? context.colors.primaryStart
                                : context.colors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name.trim(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCurrent
                            ? context.colors.primaryStart
                            : context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.tags.isNotEmpty
                          ? station.tags
                                .split(',')
                                .take(3)
                                .join(', ')
                                .toLowerCase()
                          : (station.country.isNotEmpty
                                ? station.country
                                : 'Internet Radio'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (station.bitrate > 0) ...[
                          _buildBadge(context, '${station.bitrate} kbps'),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.thumb_up_alt_outlined,
                          size: 11,
                          color: context.colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          station.votes.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Playing indicator or Favorite button
              if (isCurrent)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: isBuffering
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.primaryStart,
                              ),
                            ),
                          )
                        : (isPlaying
                              ? _buildPlayingWave(context)
                              : Icon(
                                  Icons.play_arrow_rounded,
                                  color: context.colors.primaryStart,
                                  size: 24,
                                )),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited
                        ? Colors.redAccent
                        : context.colors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(station),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  splashRadius: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.colors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPlayingWave(BuildContext context) {
    return _AnimatedMiniVisualizer(color: context.colors.primaryStart);
  }
}

class _AnimatedMiniVisualizer extends StatefulWidget {
  final Color color;
  const _AnimatedMiniVisualizer({required this.color});

  @override
  State<_AnimatedMiniVisualizer> createState() =>
      _AnimatedMiniVisualizerState();
}

class _AnimatedMiniVisualizerState extends State<_AnimatedMiniVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [12.0, 18.0, 8.0, 14.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (index) {
            final double value = (index % 2 == 0)
                ? _controller.value
                : 1.0 - _controller.value;
            final double h = 4 + (_heights[index] - 4) * value;

            return Container(
              width: 3.5,
              height: h,
              margin: const EdgeInsets.only(left: 2.5),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
