import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/mood_viewmodel.dart';
import '../models/mood.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final selectedMood = homeViewModel.selectedMood;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.psychology, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Humeur actuelle:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (selectedMood != null)
                TextButton(
                  onPressed: () {
                    homeViewModel.clearMood();
                  },
                  child: const Text(
                    'Effacer',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Mood sélectionné ou bouton de sélection
        if (selectedMood != null)
          _buildSelectedMood(context, selectedMood)
        else
          _buildMoodSelectorButton(context),

        // Moods rapides (chips)
        const SizedBox(height: 12),
        _buildQuickMoods(context),
      ],
    );
  }

  Widget _buildSelectedMood(BuildContext context, Mood mood) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: mood.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mood.color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mood.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Musique ${mood.name.toLowerCase()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Bouton changer
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/mood');
              },
              child: const Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelectorButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/mood');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.psychology, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Sélectionner une humeur',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMoods(BuildContext context) {
    final moodViewModel = context.read<MoodViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    // Prendre les 3 premiers moods pour la sélection rapide
    final quickMoods = moodViewModel.allMoods.take(3).toList();

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: quickMoods.map((mood) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${mood.emoji} ${mood.name}'),
              selected: homeViewModel.selectedMood?.id == mood.id,
              onSelected: (selected) {
                if (selected) {
                  homeViewModel.selectMood(mood);
                } else {
                  homeViewModel.clearMood();
                }
              },
              selectedColor: mood.color.withOpacity(0.3),
              backgroundColor: Colors.grey[900],
              labelStyle: TextStyle(
                color: homeViewModel.selectedMood?.id == mood.id
                    ? mood.color
                    : Colors.white,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: homeViewModel.selectedMood?.id == mood.id
                      ? mood.color
                      : Colors.grey[700]!,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}