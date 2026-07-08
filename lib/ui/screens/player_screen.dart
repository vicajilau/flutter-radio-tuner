import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/station_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/visualizer.dart';
import '../widgets/sleep_timer_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detailed audio player screen displaying album art/station favicon,
/// buffering loaders, real-time waveform visualizer, sleep timer trigger,
/// volume slider, and sharing capabilities.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    final Station? station = radioProvider.currentStation;

    // Fallback if no station is playing (shouldn't normally be reachable)
    if (station == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now Playing')),
        body: const Center(child: Text('No station selected.')),
      );
    }

    final bool isPlaying = radioProvider.isPlaying;
    final bool isBuffering = radioProvider.isBuffering;
    final bool isFavorited = favoritesProvider.isFavorite(station.stationuuid);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final systemUiOverlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: Scaffold(
        body: Stack(
          children: [
            // Background ambient gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0F1524)
                          : const Color(0xFFFFFFFF),
                      context.colors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Glow effect in the center
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.25,
              left: MediaQuery.sizeOf(context).width * 0.1,
              right: MediaQuery.sizeOf(context).width * 0.1,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primaryStart.withValues(alpha: 0.06),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primaryEnd.withValues(alpha: 0.03),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Player Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top Custom App Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 30,
                                      color: context.colors.textPrimary
                                          .withValues(alpha: 0.7),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Text(
                                    'NOW STREAMING',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          letterSpacing: 2.0,
                                          color: context.colors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      radioProvider.isSleepTimerActive
                                          ? Icons.alarm_on
                                          : Icons.alarm_add_outlined,
                                      color: radioProvider.isSleepTimerActive
                                          ? context.colors.secondary
                                          : context.colors.textPrimary
                                                .withValues(alpha: 0.7),
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => SleepTimerSheet(
                                          radioProvider: radioProvider,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Center Album Art / Wave Visualizer
                            Hero(
                              tag: 'logo_${station.stationuuid}',
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.colors.primaryStart
                                          .withValues(alpha: 0.2),
                                      blurRadius: 40,
                                      spreadRadius: -8,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: context.colors.textPrimary
                                        .withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(38.5),
                                  child: Image.network(
                                    station.favicon,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: context.colors.surfaceLight,
                                        child: Center(
                                          child: Icon(
                                            Icons.radio,
                                            size: 70,
                                            color: context.colors.textMuted,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Station Title and details
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    station.name.trim(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.textPrimary,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    [
                                      if (station.country.isNotEmpty)
                                        station.country,
                                      if (station.language.isNotEmpty)
                                        station.language.split(',').first,
                                    ].join(' • '),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: context.colors.textSecondary,
                                          fontSize: 14,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Codec & Quality Details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildBadge(
                                  context,
                                  station.codec.toUpperCase(),
                                ),
                                const SizedBox(width: 8),
                                if (station.bitrate > 0)
                                  _buildBadge(
                                    context,
                                    '${station.bitrate} kbps',
                                  ),
                              ],
                            ),

                            const Spacer(),

                            // Animated Fluid Visualizer
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Visualizer(
                                isPlaying: isPlaying,
                                height: 80,
                              ),
                            ),

                            if (radioProvider.isSleepTimerActive)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: context.colors.secondary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sleep in ${radioProvider.sleepTimeFormatted}',
                                      style: TextStyle(
                                        color: context.colors.secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () =>
                                          radioProvider.cancelSleepTimer(),
                                      child: Icon(
                                        Icons.cancel,
                                        color: context.colors.textPrimary
                                            .withValues(alpha: 0.3),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const Spacer(),

                            // Volume slider section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      radioProvider.isMuted
                                          ? Icons.volume_off
                                          : Icons.volume_down,
                                      color: context.colors.textSecondary,
                                    ),
                                    onPressed: () => radioProvider.toggleMute(),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor:
                                            context.colors.primaryStart,
                                        inactiveTrackColor: context
                                            .colors
                                            .textPrimary
                                            .withValues(alpha: 0.08),
                                        thumbColor: context.colors.textPrimary,
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 14,
                                            ),
                                      ),
                                      child: Slider(
                                        value: radioProvider.volume,
                                        onChanged: (val) =>
                                            radioProvider.setVolume(val),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.volume_up,
                                      color: context.colors.textSecondary,
                                    ),
                                    onPressed: () => radioProvider.setVolume(
                                      radioProvider.volume + 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Main Playback Controls
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48.0,
                                vertical: 24.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Share / Web Page
                                  IconButton(
                                    icon: Icon(
                                      Icons.language,
                                      color: context.colors.textSecondary,
                                      size: 26,
                                    ),
                                    onPressed: () async {
                                      final String urlString = station.homepage
                                          .trim();
                                      if (urlString.isEmpty) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'No website available for this station.',
                                              ),
                                              backgroundColor:
                                                  context.colors.surfaceLight,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      final Uri? uri = Uri.tryParse(urlString);
                                      if (uri == null ||
                                          !uri.hasScheme ||
                                          (uri.scheme != 'http' &&
                                              uri.scheme != 'https')) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Invalid station website URL.',
                                              ),
                                              backgroundColor:
                                                  context.colors.surfaceLight,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      try {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not open: $urlString',
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),

                                  // Stop Radio Button
                                  IconButton(
                                    icon: Icon(
                                      Icons.stop_rounded,
                                      color: context.colors.textSecondary,
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      radioProvider.stopRadio();
                                      Navigator.pop(context);
                                    },
                                  ),

                                  // Large Play/Pause Toggle
                                  GestureDetector(
                                    onTap: () => radioProvider.togglePlay(),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient:
                                            context.colors.primaryGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: context.colors.primaryStart
                                                .withValues(alpha: 0.35),
                                            blurRadius: 28,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: isBuffering
                                          ? const Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : Icon(
                                              isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                    ),
                                  ),

                                  // Favorite toggle
                                  IconButton(
                                    icon: Icon(
                                      isFavorited
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorited
                                          ? Colors.redAccent
                                          : context.colors.textSecondary,
                                      size: 28,
                                    ),
                                    onPressed: () => favoritesProvider
                                        .toggleFavorite(station),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
