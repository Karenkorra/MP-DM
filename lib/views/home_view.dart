import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/player_viewmodel.dart';
import '../widgets/track_tile.dart';
import '../widgets/player_controls.dart';
import '../widgets/search_bar.dart';
import '../widgets/mood_selector.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DJ Mood'),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () {
              Navigator.pushNamed(context, '/mood');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Settings view
            },
          ),
        ],
      ),
      body: SafeArea( // AJOUTÉ: Pour éviter les bords de l'écran
        child: Column(
          mainAxisSize: MainAxisSize.min, // IMPORTANT: Empêche l'expansion
          children: [
            // Mood Selector
            const Padding(
              padding: EdgeInsets.all(8.0),
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

            // Body avec Expanded - LE SEUL Expanded dans cette Column
            Expanded(
              child: Consumer<HomeViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (viewModel.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Erreur: ${viewModel.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              viewModel.searchTracks(viewModel.searchQuery);
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  final tracks = viewModel.getFilteredTracks();

                  if (tracks.isEmpty && viewModel.searchQuery.isEmpty && viewModel.selectedMood == null) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Recherchez une musique ou sélectionnez une humeur',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (tracks.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun résultat trouvé',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Essayez avec d\'autres mots-clés',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: tracks.length,
                    padding: const EdgeInsets.symmetric(vertical: 8), // Ajout de padding
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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
                },
              ),
            ),

            // Player Controls - PAS d'Expanded ici
            const PlayerControls(),
          ],
        ),
      ),
    );
  }
}