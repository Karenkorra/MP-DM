import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodCard extends StatelessWidget {
  final Mood mood;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const MoodCard({
    Key? key,
    required this.mood,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: mood.color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: mood.color.withOpacity(0.1),
        highlightColor: mood.color.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                mood.color.withOpacity(0.03),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec emoji et bouton favori
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji dans un cercle décoratif
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: mood.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            mood.color.withOpacity(0.15),
                            mood.color.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          mood.emoji,
                          size: 32,
                        ),
                      ),
                    ),

                    // Bouton favori
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Nom du mood
                Text(
                  mood.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Genres recommandés
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: mood.recommendedGenres
                      .take(3)
                      .map((genre) => _buildGenreChip(genre, mood.color))
                      .toList(),
                ),

                // Indicateur de clic (optionnel)
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: mood.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: mood.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreChip(String genre, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        genre,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}