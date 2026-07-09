import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favorites_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/extensions/context_l10n.dart';
import 'favorite_card.dart';
import 'jiggle_widget.dart';

/// A widget that displays the list of user's favorite radio stations in a
/// horizontal scrolling layout, supporting drag-and-drop reordering.
class FavoritesDeck extends ConsumerStatefulWidget {
  const FavoritesDeck({super.key});

  @override
  ConsumerState<FavoritesDeck> createState() => _FavoritesDeckState();
}

class _FavoritesDeckState extends ConsumerState<FavoritesDeck> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    debugPrint("Building FavoritesDeck");
    final favorites = ref.watch(favoritesProvider.select((s) => s.favorites));

    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            context.l10n.favoriteStations,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final station = favorites[index];
              return JiggleWidget(
                key: ValueKey(station.stationuuid),
                animate: _isReordering,
                child: FavoriteCard(station: station),
              );
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final double scale = 1.0 + (0.05 * animation.value);
                  return Transform.scale(
                    scale: scale,
                    child: Material(color: Colors.transparent, child: child),
                  );
                },
                child: child,
              );
            },
            onReorderStart: (index) {
              setState(() {
                _isReordering = true;
              });
              HapticFeedback.lightImpact();
            },
            onReorderEnd: (index) {
              setState(() {
                _isReordering = false;
              });
              HapticFeedback.mediumImpact();
            },
            onReorderItem: (oldIndex, newIndex) {
              ref
                  .read(favoritesProvider.notifier)
                  .reorderFavorites(oldIndex, newIndex);
            },
          ),
        ),
      ],
    );
  }
}
