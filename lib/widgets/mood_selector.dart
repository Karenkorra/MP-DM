import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/mood_viewmodel.dart';

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
        // Moods rapides (chips)
        _buildQuickMoods(context),
      ],
    );
  }
  Widget _buildQuickMoods(BuildContext context) {
    final moodViewModel = context.read<MoodViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    final allMoods = moodViewModel.allMoods;

    if (allMoods.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: allMoods.map((mood) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mood.emoji,
                      size: 16,
                      color: homeViewModel.selectedMood?.id == mood.id
                          ? mood.color
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(mood.name),
                  ],
                ),
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
      ),
    );
  }
}