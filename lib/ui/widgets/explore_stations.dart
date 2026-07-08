import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/extensions/context_l10n.dart';
import '../../models/station_model.dart';
import 'station_tile.dart';
import 'station_shimmer.dart';

/// Renders the section title of the explore area.
/// Automatically adjusts between "Recommended Stations" and "Search Results"
/// depending on whether active filters or queries are present.
class ExploreSectionTitle extends StatelessWidget {
  final VoidCallback onReset;

  const ExploreSectionTitle({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    debugPrint("Building ExploreSectionTitle");
    return SliverToBoxAdapter(
      child: Selector<RadioProvider, (String, String)>(
        selector: (context, provider) =>
            (provider.selectedTag, provider.searchQuery),
        builder: (context, data, child) {
          final selectedTag = data.$1;
          final searchQuery = data.$2;
          final hasFilter = selectedTag.isNotEmpty || searchQuery.isNotEmpty;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasFilter
                      ? context.l10n.searchResults
                      : context.l10n.recommendedStations,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                if (hasFilter)
                  TextButton(
                    onPressed: onReset,
                    child: Text(
                      context.l10n.reset,
                      style: TextStyle(color: context.colors.primaryStart),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Renders the explore stations list section as a sliver.
/// Listens selectively to `isLoadingData`, `stations`, `errorMessage`, `searchQuery` and `selectedTag`
/// so that it only rebuilds when search states actually change.
class ExploreStationsList extends StatelessWidget {
  final VoidCallback onReset;

  const ExploreStationsList({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final isLoadingData = context.select<RadioProvider, bool>(
      (p) => p.isLoadingData,
    );
    final stations = context.select<RadioProvider, List<Station>>(
      (p) => p.stations,
    );
    final errorMessage = context.select<RadioProvider, String?>(
      (p) => p.errorMessage,
    );
    final searchQuery = context.select<RadioProvider, String>(
      (p) => p.searchQuery,
    );
    final selectedTag = context.select<RadioProvider, String>(
      (p) => p.selectedTag,
    );
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);

    if (isLoadingData) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: StationShimmer(),
        ),
      );
    } else if (stations.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  errorMessage != null
                      ? Icons.wifi_off_rounded
                      : Icons.search_off_rounded,
                  size: 56,
                  color: context.colors.textMuted,
                ),
                const SizedBox(height: 20),
                Text(
                  errorMessage != null
                      ? context.l10n.connectionError
                      : context.l10n.noStationsFound,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  errorMessage ??
                      (searchQuery.isNotEmpty
                          ? context.l10n.searchEmptySubtitle
                          : context.l10n.noStationsAvailable),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                if (errorMessage != null)
                  GestureDetector(
                    onTap: () => radioProvider.retryInitialization(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: context.colors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primaryStart.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.retryConnection,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (searchQuery.isNotEmpty || selectedTag.isNotEmpty)
                  GestureDetector(
                    onTap: onReset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.textPrimary.withValues(
                          alpha: 0.06,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: context.colors.textPrimary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.clear_all_rounded,
                            color: context.colors.textPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.clearSearchAndFilters,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          100,
        ), // Extra space for mini player
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final station = stations[index];
            return StationTile(station: station);
          }, childCount: stations.length),
        ),
      );
    }
  }
}
