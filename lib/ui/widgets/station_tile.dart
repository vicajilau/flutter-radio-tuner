import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/station_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import 'glass_container.dart';

/// List tile widget representing a radio station in list views.
/// Renders favicon, title, tags, country code, votes count,
/// favorite toggle button, and a mini active visualizer bar if playing.
class StationTile extends StatelessWidget {
  final Station station;

  const StationTile({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = context.select<RadioProvider, bool>(
      (p) => p.currentStation?.stationuuid == station.stationuuid,
    );
    final bool isPlaying = context.select<RadioProvider, bool>(
      (p) => isCurrent && p.isPlaying,
    );
    final bool isBuffering = context.select<RadioProvider, bool>(
      (p) => isCurrent && p.isBuffering,
    );
    final bool isFavorited = context.select<FavoritesProvider, bool>(
      (p) => p.isFavorite(station.stationuuid),
    );
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => radioProvider.playStation(station),
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

              // Station Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name.trim(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isCurrent
                            ? context.colors.primaryStart
                            : context.colors.textPrimary,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (station.language.isNotEmpty)
                          station.language.split(',').first.trim(),
                        if (station.country.isNotEmpty) station.country,
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isCurrent
                            ? context.colors.textPrimary.withValues(alpha: 0.7)
                            : context.colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Tags row
                    if (station.tagList.isNotEmpty)
                      SizedBox(
                        height: 18,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: station.tagList.take(3).length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? context.colors.primaryStart.withValues(
                                        alpha: 0.15,
                                      )
                                    : context.colors.textPrimary.withValues(
                                        alpha: 0.05,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                station.tagList[index].toLowerCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.colors.textPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action Buttons / Status Indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play / Loading status icon
                  if (isCurrent) ...[
                    if (isBuffering)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.colors.primaryStart,
                          ),
                        ),
                      )
                    else if (isPlaying)
                      _buildEqualizerIndicator(context)
                    else
                      Icon(
                        Icons.pause_circle_outline,
                        color: context.colors.primaryStart,
                        size: 24,
                      ),
                    const SizedBox(width: 12),
                  ],

                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited
                          ? Colors.redAccent
                          : context.colors.textMuted,
                      size: 22,
                    ),
                    onPressed: () => favoritesProvider.toggleFavorite(station),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEqualizerIndicator(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildEqualizerBar(context, 5.0, const Duration(milliseconds: 500)),
          _buildEqualizerBar(context, 12.0, const Duration(milliseconds: 400)),
          _buildEqualizerBar(context, 8.0, const Duration(milliseconds: 600)),
        ],
      ),
    );
  }

  Widget _buildEqualizerBar(
    BuildContext context,
    double height,
    Duration duration,
  ) {
    return _EqualizerBarAnimation(maxHeight: height, duration: duration);
  }
}

/// Internal widget to animate a single vertical equalizer frequency bar.
class _EqualizerBarAnimation extends StatefulWidget {
  final double maxHeight;
  final Duration duration;

  const _EqualizerBarAnimation({
    required this.maxHeight,
    required this.duration,
  });

  @override
  State<_EqualizerBarAnimation> createState() => _EqualizerBarAnimationState();
}

/// State management for the single equalizer frequency bar animation controller.
class _EqualizerBarAnimationState extends State<_EqualizerBarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: 2.0,
      end: widget.maxHeight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 3.5,
          height: _animation.value,
          decoration: BoxDecoration(
            color: context.colors.primaryStart,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
