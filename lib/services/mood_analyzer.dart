import '../models/mood.dart';

class MoodAnalyzer {
  // Score pour chaque humeur
  Map<String, int> _moodScores = {
    'happy': 0,
    'sad': 0,
    'energetic': 0,
    'chill': 0,
    'romantic': 0,
  };

  // Mots-clés avec poids pour chaque humeur
  final Map<String, Map<String, int>> _moodKeywords = {
    'happy': {
      'heureux': 3, 'joyeux': 3, 'content': 3, 'heureuse': 3,
      'joie': 2, 'sourire': 2, 'rire': 2, 'amusement': 2,
      'fête': 2, 'célébration': 2, 'gai': 2, 'optimiste': 2,
      'positif': 2, 'soleil': 1, 'été': 1, 'vacances': 1,
      'danser': 1, 'chanter': 1, 'victoire': 1, 'réussite': 1,
    },
    'sad': {
      'triste': 3, 'tristesse': 3, 'pleurer': 3, 'malheureux': 3,
      'déprimé': 3, 'déception': 2, 'désespoir': 2, 'solitude': 2,
      'seul': 2, 'abandonné': 2, 'perdu': 2, 'cœur brisé': 2,
      'déchiré': 2, 'larmes': 2, 'douleur': 2, 'chagrin': 2,
      'mélancolie': 2, 'pluie': 1, 'nuit': 1, 'obscurité': 1,
    },
    'energetic': {
      'énergique': 3, 'énergie': 3, 'motivé': 3, 'dynamique': 3,
      'puissant': 2, 'fort': 2, 'intense': 2, 'puissance': 2,
      'adrénaline': 2, 'excité': 2, 'enthousiaste': 2, 'vif': 2,
      'rapide': 2, 'sport': 1, 'entraînement': 1, 'course': 1,
      'danse': 1, 'fête': 1, 'feu': 1, 'explosion': 1,
    },
    'chill': {
      'détendu': 3, 'calme': 3, 'relax': 3, 'paisible': 3,
      'zen': 2, 'tranquille': 2, 'serein': 2, 'repos': 2,
      'silence': 2, 'douceur': 2, 'apaisant': 2, 'méditation': 2,
      'yoga': 1, 'reposant': 2, 'lent': 1, 'doux': 1,
      'nature': 1, 'plage': 1, 'forêt': 1, 'vacances': 1,
    },
    'romantic': {
      'amour': 3, 'romantique': 3, 'cœur': 3, 'amoureux': 3,
      'passion': 2, 'désir': 2, 'tendresse': 2, 'affection': 2,
      'intimité': 2, 'baiser': 2, 'étreinte': 2, 'sentimental': 2,
      'doux': 1, 'soirée': 1, 'nuit': 1, 'coup de foudre': 2,
      'rencontre': 1, 'dîner': 1, 'bougie': 1, 'rose': 1,
    },
  };

  // Négations qui diminuent le score
  final List<String> _negations = [
    'pas', 'ne', 'non', 'jamais', 'sans', 'peu', 'guère'
  ];

  Future<Mood> analyzeText(String text) async {
    if (text.isEmpty) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'chill');
    }

    _resetScores();
    final lowerText = text.toLowerCase();
    final words = _extractWords(lowerText);

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      bool isNegated = _isWordNegated(words, i);

      for (final mood in _moodScores.keys) {
        if (_moodKeywords[mood]!.containsKey(word)) {
          int weight = _moodKeywords[mood]![word]!;

          // Si le mot est nié, on soustrait au lieu d'ajouter
          if (isNegated) {
            _moodScores[mood] = _moodScores[mood]! - weight;
          } else {
            _moodScores[mood] = _moodScores[mood]! + weight;
          }
        }
      }
    }

    return _getMoodFromScores();
  }

  // Analyser l'intensité du texte (0-100)
  Future<int> analyzeIntensity(String text) async {
    if (text.isEmpty) return 50;

    final words = text.split(' ');
    int intensity = 50; // Valeur neutre

    // Mots qui indiquent une forte intensité
    final intenseWords = ['très', 'extrêmement', 'incroyablement',
      'totalement', 'absolument', 'vraiment', 'tellement'];

    final punctuation = text.replaceAll(RegExp(r'[^!?]'), '');
    intensity += punctuation.length * 5;

    for (final word in words) {
      if (intenseWords.contains(word.toLowerCase())) {
        intensity += 10;
      }
    }

    return intensity.clamp(0, 100);
  }

  // Analyser plusieurs textes (pour l'historique)
  Future<Mood> analyzeMultipleTexts(List<String> texts) async {
    _resetScores();

    for (final text in texts) {
      final mood = await analyzeText(text);
      _moodScores[mood.id] = _moodScores[mood.id]! + 1;
    }

    return _getMoodFromScores();
  }

  // Obtenir la confiance de l'analyse (0-100%)
  int getConfidence(Map<String, int> scores) {
    final totalScore = scores.values.fold(0, (sum, score) => sum + score.abs());
    if (totalScore == 0) return 0;

    final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
    return ((maxScore / totalScore) * 100).round();
  }

  // Obtenir les scores détaillés (pour affichage)
  Map<String, Map<String, dynamic>> getDetailedAnalysis(String text) {
    final Map<String, Map<String, dynamic>> analysis = {};

    for (final moodId in _moodScores.keys) {
      final mood = Mood.predefinedMoods.firstWhere((m) => m.id == moodId);
      analysis[moodId] = {
        'mood': mood,
        'score': _moodScores[moodId],
        'keywords': _findKeywordsInText(text, moodId),
      };
    }

    return analysis;
  }

  // Méthodes privées
  List<String> _extractWords(String text) {
    return text.split(RegExp(r'[ ,.!?;:\-\n]+')).where((w) => w.isNotEmpty).toList();
  }

  bool _isWordNegated(List<String> words, int index) {
    if (index > 0) {
      for (int i = index - 1; i >= 0 && i >= index - 3; i--) {
        if (_negations.contains(words[i])) {
          return true;
        }
      }
    }
    return false;
  }

  void _resetScores() {
    for (final key in _moodScores.keys) {
      _moodScores[key] = 0;
    }
  }

  Mood _getMoodFromScores() {
    String topMood = 'chill';
    int maxScore = -999;

    for (final entry in _moodScores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        topMood = entry.key;
      }
    }

    // Si aucun score positif, retourner chill par défaut
    if (maxScore <= 0) {
      return Mood.predefinedMoods.firstWhere((m) => m.id == 'chill');
    }

    return Mood.predefinedMoods.firstWhere((m) => m.id == topMood);
  }

  List<String> _findKeywordsInText(String text, String moodId) {
    final lowerText = text.toLowerCase();
    final keywords = _moodKeywords[moodId]!.keys;
    final found = keywords.where((keyword) => lowerText.contains(keyword)).toList();
    return found.take(3).toList(); // Limiter à 3 mots-clés
  }

  // Analyse de titre de chanson (héritée)
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