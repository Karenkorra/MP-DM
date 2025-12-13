import '../models/mood.dart';

class MoodAnalyzer {
  // Pour phase 1: analyse basée sur mots-clés
  // Phase 2: on ajoutera ML local ou appel API

  Future<Mood> analyzeText(String text) async {
    final lowerText = text.toLowerCase();

    // Détection basique par mots-clés
    if (lowerText.contains('heureux') ||
        lowerText.contains('joyeux') ||
        lowerText.contains('content')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'happy');
    }

    if (lowerText.contains('triste') ||
        lowerText.contains('tristesse') ||
        lowerText.contains('pleurer')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'sad');
    }

    if (lowerText.contains('énergique') ||
        lowerText.contains('énergie') ||
        lowerText.contains('motivé')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'energetic');
    }

    if (lowerText.contains('détendu') ||
        lowerText.contains('calme') ||
        lowerText.contains('relax')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'chill');
    }

    if (lowerText.contains('amour') ||
        lowerText.contains('romantique') ||
        lowerText.contains('cœur')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'romantic');
    }

    // Par défaut: mood neutre/chill
    return Mood.predefinedMoods.firstWhere((m) => m.id == 'chill');
  }

  // Analyse à partir d'un titre de musique
  Mood analyzeTrackTitle(String title) {
    final lowerTitle = title.toLowerCase();

    // Détection basique dans les titres
    if (lowerTitle.contains('happy') || lowerTitle.contains('sunshine')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'happy');
    }

    if (lowerTitle.contains('sad') || lowerTitle.contains('rain')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'sad');
    }

    if (lowerTitle.contains('energy') || lowerTitle.contains('fire')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'energetic');
    }

    if (lowerTitle.contains('chill') || lowerTitle.contains('calm')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'chill');
    }

    if (lowerTitle.contains('love') || lowerTitle.contains('heart')) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'romantic');
    }

    return Mood.predefinedMoods.firstWhere((m) => m.id == 'chill');
  }
}