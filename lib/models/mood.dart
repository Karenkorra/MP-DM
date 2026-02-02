import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Mood {
  final String id;
  final String name;
  final IconData emoji;
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
      emoji: FontAwesomeIcons.faceSmileBeam,
      color: Colors.yellow,
      recommendedGenres: ['Pop', 'Disco', 'Funk', 'Reggae'],
      createdAt: DateTime.now(),
    ),
    Mood(
      id: 'sad',
      name: 'Triste',
      emoji: FontAwesomeIcons.faceSadTear,
      color: Colors.blue,
      recommendedGenres: ['Blues', 'Jazz', 'Soul', 'Acoustic'],
      createdAt: DateTime.now(),
    ),
    Mood(
      id: 'energetic',
      name: 'Énergique',
      emoji:FontAwesomeIcons.bolt,
      color: Colors.orange,
      recommendedGenres: ['Rock', 'Metal', 'EDM', 'Hip Hop'],
      createdAt: DateTime.now(),
    ),
    Mood(
      id: 'chill',
      name: 'Détendu',
      emoji:FontAwesomeIcons.couch,
      color: Colors.green,
      recommendedGenres: ['Lo-fi', 'Ambient', 'Chillout', 'Jazz'],
      createdAt: DateTime.now(),
    ),
    Mood(
      id: 'romantic',
      name: 'Romantique',
      emoji:  FontAwesomeIcons.heart,
      color: Colors.pink,
      recommendedGenres: ['R&B', 'Soul', 'Classical', 'Pop Ballad'],
      createdAt: DateTime.now(),
    ),
  ];
}