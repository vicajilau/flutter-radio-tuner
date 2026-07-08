import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';

/// Horizontal list widget for browsing and filtering radio stations by popular genres.
/// Displays interactive chips indicating selection states.
class GenreSelector extends StatelessWidget {
  const GenreSelector({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("Building GenreSelector");
    final tags = context.select<RadioProvider, List<String>>((p) => p.tags);
    final selectedTag = context.select<RadioProvider, String>(
      (p) => p.selectedTag,
    );
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Text(
            'Popular Genres',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
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
                  onTap: () => radioProvider.search(tag: tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected
                          ? null
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
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
