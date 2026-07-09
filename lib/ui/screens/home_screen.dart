import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/browser_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/extensions/context_l10n.dart';
import '../widgets/glass_container.dart';
import '../widgets/mini_player.dart';
import '../widgets/favorites_deck.dart';
import '../widgets/history_tile.dart';
import '../widgets/genre_selector.dart';
import '../widgets/explore_stations.dart';

/// Main landing screen of the application containing the dashboard,
/// search bar, popular genres, recently played list, and stations list.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// State management for [HomeScreen] that handles focus, input controllers, and search debouncing.
class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _resetSearch() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(browserProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
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
            // Background ambient glows
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primaryStart.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primaryEnd.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Main Layout
            SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(browserProvider.notifier).refreshData();
                },
                color: context.colors.primaryStart,
                backgroundColor: context.colors.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Premium App Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.appTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(fontSize: 30),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.l10n.streamWorldsMusic,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: context.colors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                            // Top Logo Indicator
                            Image.asset(
                              'assets/icon/app_icon_transparent.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10.0,
                        ),
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          opacity: 0.05,
                          borderRadius: BorderRadius.circular(18),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (val) {
                              _debounce?.cancel();
                              if (val.isEmpty) {
                                ref
                                    .read(browserProvider.notifier)
                                    .search(query: val);
                              } else {
                                _debounce = Timer(
                                  const Duration(milliseconds: 500),
                                  () => ref
                                      .read(browserProvider.notifier)
                                      .search(query: val),
                                );
                              }
                            },
                            style: TextStyle(color: context.colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: context.l10n.searchPlaceholder,
                              hintStyle: TextStyle(
                                color: context.colors.textMuted,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: context.colors.textSecondary,
                              ),
                              suffixIcon:
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _searchController,
                                    builder: (context, value, child) {
                                      return value.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                color: context
                                                    .colors
                                                    .textSecondary,
                                              ),
                                              onPressed: () {
                                                _resetSearch();
                                                _searchFocusNode.unfocus();
                                              },
                                            )
                                          : const SizedBox.shrink();
                                    },
                                  ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Category Tabs (Tags)
                    const SliverToBoxAdapter(child: GenreSelector()),

                    // Favorites Deck (horizontal card scroll)
                    const SliverToBoxAdapter(child: FavoritesDeck()),

                    // Recently Played History
                    SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final historyStations = ref.watch(
                            browserProvider.select((s) => s.historyStations),
                          );
                          if (historyStations.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.l10n.recentlyPlayed,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.textPrimary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(browserProvider.notifier)
                                            .clearFilters();
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child:
                                          const SizedBox.shrink(), // placeholder
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: historyStations.length,
                                  itemBuilder: (context, index) {
                                    final station = historyStations[index];
                                    return HistoryTile(station: station);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Error Message banner
                    SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final data = ref.watch(
                            browserProvider.select(
                              (s) => (s.errorMessage, s.stations.isNotEmpty),
                            ),
                          );
                          final errorMessage = data.$1;
                          final hasStations = data.$2;
                          if (errorMessage == null || !hasStations) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Explore Section Title
                    ExploreSectionTitle(onReset: _resetSearch),

                    // Explore Station List (rebuilds granularly on search query/results change)
                    ExploreStationsList(onReset: _resetSearch),
                  ],
                ),
              ),
            ),

            // Bottom Floating Mini Player
            const Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
          ],
        ),
      ),
    );
  }
}
