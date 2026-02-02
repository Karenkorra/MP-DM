import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../services/mood_analyzer.dart';

class TextAnalysisViewModel extends ChangeNotifier {
  final MoodAnalyzer _moodAnalyzer = MoodAnalyzer();

  // ÉTAT
  Mood? _currentMood;
  Map<String, dynamic>? _lastAnalysis;
  bool _isAnalyzing = false;

  // GETTERS
  Mood? get currentMood => _currentMood;
  Map<String, dynamic>? get lastAnalysis => _lastAnalysis;
  bool get isAnalyzing => _isAnalyzing;

  // ACTIONS
  Future<void> analyzeText(String text) async {
    print('🔍 [ViewModel] Début analyse - isAnalyzing: $_isAnalyzing, texte: "$text"');

    if (text.isEmpty) {
      print('❌ [ViewModel] Texte vide, analyse annulée');
      return;
    }

    _isAnalyzing = true;
    print('🔍 [ViewModel] isAnalyzing = true');
    notifyListeners();

    // Petit délai pour voir l'état
    await Future.delayed(Duration(milliseconds: 50));

    try {
      print('🔍 [ViewModel] Début analyse mood...');
      // Analyser l'humeur
      final mood = await _moodAnalyzer.analyzeText(text);
      print('🔍 [ViewModel] Humeur détectée: ${mood.name}');

      // Analyser l'intensité
      print('🔍 [ViewModel] Analyse intensité...');
      final intensity = await _moodAnalyzer.analyzeIntensity(text);
      print('🔍 [ViewModel] Intensité: $intensity');

      // Obtenir l'analyse détaillée
      print('🔍 [ViewModel] Analyse détaillée...');
      final detailedAnalysis = _moodAnalyzer.getDetailedAnalysis(text);
      print('🔍 [ViewModel] Analyse détaillée obtenue');

      // Calculer la confiance
      print('🔍 [ViewModel] Calcul confiance...');
      Map<String, int> scores = {};
      for (var entry in detailedAnalysis.entries) {
        scores[entry.key] = entry.value['score'] as int;
      }
      final confidence = _moodAnalyzer.getConfidence(scores);
      print('🔍 [ViewModel] Confiance: $confidence%');

      // Extraire les mots-clés pour cette humeur
      final keywords = detailedAnalysis[mood.id]?['keywords'] as List<String>? ?? [];
      print('🔍 [ViewModel] Mots-clés: $keywords');

      _currentMood = mood;
      _lastAnalysis = {
        'text': text,
        'mood': mood,
        'intensity': intensity,
        'confidence': confidence,
        'keywords': keywords,
        'timestamp': DateTime.now().toIso8601String(),
        'detailed': detailedAnalysis,
      };

      print('✅ [ViewModel] Analyse terminée avec succès');
      print('✅ [ViewModel] Humeur finale: ${_currentMood?.name}');

    } catch (e) {
      print('❌ [ViewModel] Erreur analyse texte: $e');
      _currentMood = Mood.predefinedMoods.firstWhere((m) => m.id == 'chill');
      _lastAnalysis = {
        'text': text,
        'mood': _currentMood,
        'intensity': 50,
        'confidence': 0,
        'keywords': [],
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    } finally {
      print('🔍 [ViewModel] finally - isAnalyzing = false');
      _isAnalyzing = false;
      notifyListeners();
      print('🔍 [ViewModel] notifyListeners appelé');

      // Vérification après reset
      Future.delayed(Duration(milliseconds: 100), () {
        print('🔍 [ViewModel] Vérification après reset - isAnalyzing: $_isAnalyzing');
      });
    }
  }

  // Réinitialiser l'analyse courante
  void clearCurrentAnalysis() {
    print('🔍 [ViewModel] clearCurrentAnalysis appelé');
    _currentMood = null;
    _lastAnalysis = null;
    notifyListeners();
  }

  // Méthode d'initialisation
  Future<void> initialize() async {
    print('✅ TextAnalysisViewModel initialisé');
  }

  @override
  void dispose() {
    print('🔍 [ViewModel] dispose');
    super.dispose();
  }
}