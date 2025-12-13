import 'dart:ui';
import 'package:flutter/material.dart';

class Mood {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final List<String> recommendedGenres;
  final DateTime createdAt;


  // Construit une instance de Mood avec toutes les informations nécessaires
  Mood({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.recommendedGenres,
    required this.createdAt,
  });

  //Une liste statique d’humeurs prédéfinies  pour la première phase du projet
  static final List<Mood> predefinedMoods = [
    Mood(
      id: 'happy',
      name: 'Heureux',
      emoji: '😊',
      color: Colors.yellow,
      recommendedGenres: ['Pop', 'Disco', 'Funk', 'Reggae'],
      createdAt: DateTime.now(),
    ),
    Mood(
      id: 'sad',
      name: 'Triste',
      emoji: '😢',
      color: Colors.blue,
      recommendedGenres: ['Blues', 'Jazz', 'Soul', 'Acoustic'],
      createdAt: DateTime.now(),
    ),
    Mood(
      id: 'energetic',
      name: 'Énergique',
      emoji: '⚡',
      color: Colors.orange,
      recommendedGenres: ['Rock', 'Metal', 'EDM', 'Hip Hop'],
      createdAt: DateTime.now(),
    ),
    Mood(
      id: 'chill',
      name: 'Détendu',
      emoji: '😌',
      color: Colors.green,
      recommendedGenres: ['Lo-fi', 'Ambient', 'Chillout', 'Jazz'],
      createdAt: DateTime.now(),
    ),
    Mood(
      id: 'romantic',
      name: 'Romantique',
      emoji: '🥰',
      color: Colors.pink,
      recommendedGenres: ['R&B', 'Soul', 'Classical', 'Pop Ballad'],
      createdAt: DateTime.now(),
    ),
  ];
}