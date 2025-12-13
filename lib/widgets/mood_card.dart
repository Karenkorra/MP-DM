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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji - taille réduite
              Container(
                height: 48, // Hauteur fixe pour l'emoji
                alignment: Alignment.center,
                child: Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),

              const SizedBox(height: 6),

              // Nom
              Text(
                mood.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Genres
              const SizedBox(height: 6),
              Container(
                height: 40, // Hauteur fixe pour les chips
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: mood.recommendedGenres
                      .take(2)
                      .map((genre) => Chip(
                    label: Text(
                      genre,
                      style: const TextStyle(fontSize: 9),
                    ),
                    backgroundColor: mood.color.withOpacity(0.1),
                    labelStyle: TextStyle(
                      fontSize: 9,
                      color: mood.color,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
                      .toList(),
                ),
              ),

              // Favorite button - en position absolue ou avec espacement contrôlé
              Container(
                height: 40, // Hauteur fixe pour le bouton
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 20, // Taille réduite
                  ),
                  onPressed: onFavoriteToggle,
                  padding: EdgeInsets.zero, // Supprime le padding interne
                  constraints: const BoxConstraints(
                    minWidth: 36, // Taille minimale réduite
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}