import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/browser_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/extensions/context_l10n.dart';

/// Horizontal list widget for browsing and filtering radio stations by popular genres.
/// Displays interactive chips indicating selection states.
class GenreSelector extends ConsumerWidget {
  const GenreSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("Building GenreSelector");
    final tags = ref.watch(browserProvider.select((p) => p.tags));
    final selectedTag = ref.watch(browserProvider.select((p) => p.selectedTag));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Text(
            context.l10n.popularGenres,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final isSelected = selectedTag == tag;

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () =>
                      ref.read(browserProvider.notifier).search(tag: tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? context.colors.primaryGradient
                          : null,
                      color: isSelected
                          ? null
                          : context.colors.textPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : context.colors.textPrimary.withValues(
                                alpha: 0.05,
                              ),
                      ),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : context.colors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
