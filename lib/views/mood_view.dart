import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/mood_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/mood_card.dart';

class MoodView extends StatelessWidget {
  const MoodView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final moodViewModel = context.read<MoodViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionnez votre humeur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              const Text(
                'Comment vous sentez-vous ?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez une humeur pour découvrir de la musique adaptée',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Moods prédéfinis
              const Text(
                'Humeurs populaires:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Grille de moods - CORRECTION PRINCIPALE
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9, // Ajusté pour plus d'espace
                  ),
                  itemCount: moodViewModel.allMoods.length,
                  itemBuilder: (context, index) {
                    final mood = moodViewModel.allMoods[index];
                    final isFavorite = moodViewModel.isFavorite(mood);

                    return MoodCard(
                      mood: mood,
                      isFavorite: isFavorite,
                      onTap: () {
                        moodViewModel.selectMood(mood);
                        homeViewModel.selectMood(mood);
                        Navigator.pop(context);
                      },
                      onFavoriteToggle: () {
                        moodViewModel.toggleFavorite(mood);
                      },
                    );
                  },
                ),
              ),

              // Humeur récentes (si disponibles)
              if (moodViewModel.recentMoods.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Récentes:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60, // Hauteur réduite
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: moodViewModel.recentMoods.length,
                    itemBuilder: (context, index) {
                      final mood = moodViewModel.recentMoods[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            moodViewModel.selectMood(mood);
                            homeViewModel.selectMood(mood);
                            Navigator.pop(context);
                          },
                          child: Chip(
                            label: Text('${mood.emoji} ${mood.name}'),
                            backgroundColor: mood.color.withOpacity(0.1),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}