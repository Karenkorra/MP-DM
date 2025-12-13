import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodViewModel extends ChangeNotifier {
  // ÉTAT
  Mood? _selectedMood;
  List<Mood> _recentMoods = [];
  List<Mood> _favoriteMoods = [];

  // GETTERS
  Mood? get selectedMood => _selectedMood;
  List<Mood> get recentMoods => _recentMoods;
  List<Mood> get favoriteMoods => _favoriteMoods;
  List<Mood> get allMoods => Mood.predefinedMoods;

  // ACTIONS
  void selectMood(Mood mood) {
    _selectedMood = mood;

    // Ajouter aux récents (limité à 5)
    if (!_recentMoods.contains(mood)) {
      _recentMoods.insert(0, mood);
      if (_recentMoods.length > 5) {
        _recentMoods.removeLast();
      }
    }

    notifyListeners();
  }

  void toggleFavorite(Mood mood) {
    if (_favoriteMoods.contains(mood)) {
      _favoriteMoods.remove(mood);
    } else {
      _favoriteMoods.add(mood);
    }

    notifyListeners();
  }

  void clearSelection() {
    _selectedMood = null;
    notifyListeners();
  }

  // Recherche de moods
  List<Mood> searchMoods(String query) {
    if (query.isEmpty) return allMoods;

    return allMoods.where((mood) {
      return mood.name.toLowerCase().contains(query.toLowerCase()) ||
          mood.recommendedGenres.any((genre) =>
              genre.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  // Vérifier si un mood est favori
  bool isFavorite(Mood mood) {
    return _favoriteMoods.contains(mood);
  }
}