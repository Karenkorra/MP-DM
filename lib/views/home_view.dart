import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';import '../models/track.dart';

import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/player_viewmodel.dart';
import '../viewmodels/text_analysis_viewmodel.dart';
import '../widgets/track_tile.dart';
import '../widgets/player_controls.dart';
import '../widgets/search_bar.dart';
import '../widgets/mood_selector.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  final TextEditingController _moodTextController = TextEditingController();
  final FocusNode _moodTextFocus = FocusNode();
  bool _showMoodAnalysis = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _moodTextController.dispose();
    _moodTextFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMoodAnalysis() {
    setState(() {
      _showMoodAnalysis = !_showMoodAnalysis;
      if (_showMoodAnalysis) {
        _animationController.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          _moodTextFocus.requestFocus();
        });
      } else {
        _animationController.reverse();
        _moodTextController.clear();
      }
    });
  }

  Future<void> _analyzeMood(BuildContext context) async {
    if (_moodTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer du texte pour analyser votre humeur'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final textViewModel = context.read<TextAnalysisViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    // Analyser le texte
    await textViewModel.analyzeText(_moodTextController.text.trim());

    // Récupérer l'humeur détectée
    if (textViewModel.currentMood != null) {
      // Appliquer l'humeur détectée
      await homeViewModel.selectMood(textViewModel.currentMood!);

      // Afficher un feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(  // Utilisez Icon au lieu de Text
                  textViewModel.currentMood!.emoji,
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Humeur détectée: ${textViewModel.currentMood!.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: textViewModel.currentMood!.color,
            duration: const Duration(seconds: 3),
          ),
        );

        // Masquer le champ de texte
        _toggleMoodAnalysis();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.black26,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/Logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.music_note, color: Colors.white);
            },
          ),
        ),
        title: const Text(
          'DJ Mood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          // Bouton analyse de texte
          IconButton(
            icon: Icon(
              _showMoodAnalysis ? Icons.close : Icons.chat_bubble_outline,
              color: _showMoodAnalysis ? Colors.amber : Colors.white,
            ),
            onPressed: _toggleMoodAnalysis,
            tooltip: 'Analyser mon humeur par texte',
          ),
          // Bouton sélection humeur
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900.withOpacity(0.3),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Mood Selector
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MoodSelector(),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SearchBar(
                  onSearch: (query) {
                    context.read<HomeViewModel>().searchTracks(query);
                  },
                ),
              ),

              // Body principal
              Expanded(
                child: Consumer<HomeViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.deepPurple.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Recherche en cours...',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (viewModel.errorMessage != null) {
                      return _buildErrorView(context, viewModel);
                    }

                    final tracks = viewModel.getFilteredTracks();

                    if (tracks.isEmpty &&
                        viewModel.searchQuery.isEmpty &&
                        viewModel.selectedMood == null) {
                      return _buildEmptyState(context);
                    }

                    if (tracks.isEmpty) {
                      return _buildNoResultsView(context);
                    }

                    return _buildTracksList(tracks, context);
                  },
                ),
              ),

              // Player Controls
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showMoodAnalysis
                    ? _buildMoodAnalysisField(context)
                    : const SizedBox.shrink(),
              ),
              const PlayerControls(),
            ],
          ),
        ),
      ),

      floatingActionButton: !_showMoodAnalysis
          ? FloatingActionButton(
        onPressed: _toggleMoodAnalysis,
        backgroundColor: Colors.deepPurple,
        tooltip: 'Analyser mon humeur par texte',
        child: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
        ),
      )
          : null,
    );
  }

  Widget _buildMoodAnalysisField(BuildContext context) {
    return Consumer<TextAnalysisViewModel>(
      builder: (context, textViewModel, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 📝 Conteneur principal du champ de texte
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.deepPurple.shade400.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      /// 📝 Champ de texte
                      Expanded(
                        child: TextField(
                          controller: _moodTextController,
                          focusNode: _moodTextFocus,
                          maxLines: null,
                          minLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Décris ton humeur...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) =>
                          textViewModel.isAnalyzing ? null : _analyzeMood(context),
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// 🚀 Bouton envoyer
                      GestureDetector(
                        onTap: textViewModel.isAnalyzing
                            ? null
                            : () => _analyzeMood(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: textViewModel.isAnalyzing
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.deepPurple.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: textViewModel.isAnalyzing
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 15),
                child: GestureDetector(
                  onTap: textViewModel.isAnalyzing
                      ? null
                      : () {
                    _moodTextController.clear();
                    _moodTextFocus.unfocus();
                    setState(() {
                      _showMoodAnalysis = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.amber,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildErrorView(BuildContext context, HomeViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oups ! Une erreur est survenue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              viewModel.errorMessage ?? 'Erreur inconnue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                viewModel.searchTracks(viewModel.searchQuery);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône animée
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepPurple.shade600.withOpacity(0.3),
                            Colors.deepPurple.shade800.withOpacity(0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 50,
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Comment vous sentez-vous ?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildNoResultsView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Essayez avec d\'autres mots-clés\nou sélectionnez une humeur',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksList(List<Track> tracks, BuildContext context) {
    return ListView.builder(
      itemCount: tracks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: TrackTile(
            track: track,
            onTap: () {
              context.read<PlayerViewModel>().playTrack(track);
            },
          ),
        );
      },
    );
  }
}