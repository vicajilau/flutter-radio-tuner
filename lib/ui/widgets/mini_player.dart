import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../screens/player_screen.dart';
import 'glass_container.dart';

/// Persistent mini player widget displayed at the bottom of the home screen.
/// Provides access to quick playback controls (play/pause, favorite toggle)
/// and displays the current station name with a sliding transition to the full player.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    final currentStation = radioProvider.currentStation;
    if (currentStation == null) return const SizedBox.shrink();

    final isPlaying = radioProvider.isPlaying;
    final isBuffering = radioProvider.isBuffering;
    final isFavorited = favoritesProvider.isFavorite(
      currentStation.stationuuid,
    );
    final bool isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PlayerScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeOutCubic;
                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            opacity: 0.15,
            borderOpacity: 0.2,
            border: Border.all(
              color: context.colors.primaryStart.withValues(alpha: 0.2),
              width: 1.0,
            ),
            child: Row(
              children: [
                // Station Logo
                Hero(
                  tag: 'logo_${currentStation.stationuuid}',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.textPrimary.withValues(
                          alpha: 0.05,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        currentStation.favicon,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: context.colors.surfaceLight,
                            child: Center(
                              child: Icon(
                                Icons.radio,
                                size: 20,
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
                const SizedBox(width: 12),

                // Station Title / Bitrate
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentStation.name.trim(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBuffering
                            ? 'Buffering stream...'
                            : '${isPlaying ? 'Playing Live' : 'Paused'}${currentStation.bitrate > 0 ? '  •  ${currentStation.bitrate} kbps' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: isBuffering
                              ? context.colors.primaryStart
                              : (isPlaying
                                    ? context.colors.secondary
                                    : context.colors.textSecondary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite button (only shown in landscape mode to save horizontal space)
                    if (!isPortrait) ...[
                      IconButton(
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited
                              ? Colors.redAccent
                              : context.colors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            favoritesProvider.toggleFavorite(currentStation),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        splashRadius: 20,
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Play/Pause button
                    GestureDetector(
                      onTap: () => radioProvider.togglePlay(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: context.colors.primaryGradient,
                        ),
                        child: isBuffering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Close/Stop player button
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.colors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => radioProvider.stopRadio(),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
