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
    final radioProvider = Provider.of<RadioProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    final bool isCurrent =
        radioProvider.currentStation?.stationuuid == station.stationuuid;
    final bool isPlaying = isCurrent && radioProvider.isPlaying;
    final bool isBuffering = isCurrent && radioProvider.isBuffering;
    final bool isFavorited = favoritesProvider.isFavorite(station.stationuuid);

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
                  color: AppTheme.primaryStart.withValues(alpha: 0.5),
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
                      AppTheme.surfaceLight,
                      isCurrent
                          ? AppTheme.primaryStart.withValues(alpha: 0.3)
                          : AppTheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isCurrent
                        ? AppTheme.primaryStart.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
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
                                ? AppTheme.primaryStart
                                : Colors.white60,
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
                            ? AppTheme.primaryStart
                            : AppTheme.textPrimary,
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
                            ? Colors.white70
                            : AppTheme.textSecondary,
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
                                    ? AppTheme.primaryStart.withValues(
                                        alpha: 0.15,
                                      )
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                station.tagList[index].toLowerCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
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
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryStart,
                          ),
                        ),
                      )
                    else if (isPlaying)
                      _buildEqualizerIndicator()
                    else
                      const Icon(
                        Icons.pause_circle_outline,
                        color: AppTheme.primaryStart,
                        size: 24,
                      ),
                    const SizedBox(width: 12),
                  ],

                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? Colors.redAccent : Colors.white38,
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

  Widget _buildEqualizerIndicator() {
    return SizedBox(
      width: 16,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildEqualizerBar(5.0, const Duration(milliseconds: 500)),
          _buildEqualizerBar(12.0, const Duration(milliseconds: 400)),
          _buildEqualizerBar(8.0, const Duration(milliseconds: 600)),
        ],
      ),
    );
  }

  Widget _buildEqualizerBar(double height, Duration duration) {
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
            color: AppTheme.primaryStart,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
