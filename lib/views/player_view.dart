import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/player_viewmodel.dart';
import '../widgets/player_controls.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({Key? key}) : super(key: key);

  // Helper pour obtenir la couleur basée sur la source
  Color _getSourceColor(String source) {
    switch (source) {
      case 'soundcloud':
        return const Color(0xFFff3300);
      case 'audius':
        return const Color(0xFF8B5CF6);
      case 'jamendo':
        return const Color(0xFF00A2FF);
      case 'local':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  // Helper pour obtenir le nom affichable
  String _getSourceName(String source) {
    switch (source) {
      case 'soundcloud':
        return 'SoundCloud';
      case 'audius':
        return 'Audius';
      case 'jamendo':
        return 'Jamendo';
      case 'local':
        return 'Appareil';
      default:
        return source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlayerViewModel>();
    final track = viewModel.currentTrack;

    if (track == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lecteur'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'Aucune musique en cours',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Retournez à l\'accueil pour sélectionner une musique',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sourceColor = _getSourceColor(track.source);
    final sourceName = _getSourceName(track.source);

    return Scaffold(
      appBar: AppBar(
        title: const Text('En écoute'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Bouton playlist
          if (viewModel.playlist.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.queue_music),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Playlist'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: viewModel.playlist.length,
                        itemBuilder: (context, index) {
                          final playlistTrack = viewModel.playlist[index];
                          final isCurrent = playlistTrack.id == track.id;
                          return ListTile(
                            leading: Icon(
                              Icons.music_note,
                              color: isCurrent ? sourceColor : Colors.grey,
                            ),
                            title: Text(
                              playlistTrack.title,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent ? sourceColor : null,
                              ),
                            ),
                            subtitle: Text(playlistTrack.artist),
                            onTap: () {
                              viewModel.playTrack(playlistTrack);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Album Art - Partie supérieure avec effet de dégradé
          Expanded(
            flex: 3, // Augmenté de 2 à 3 pour donner plus d'espace à l'image
            child: Stack(
              children: [
                // Fond de dégradé basé sur la couleur de la source
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        sourceColor.withOpacity(0.8),
                        sourceColor.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Image d'album ou placeholder
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Hero(
                      tag: 'album_art_${track.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            track.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAlbumArtPlaceholder(sourceColor);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildAlbumArtPlaceholder(sourceColor);
                            },
                          ),
                        )
                            : _buildAlbumArtPlaceholder(sourceColor),
                      ),
                    ),
                  ),
                ),

                // Overlay d'informations en haut
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Source info
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: sourceColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sourceColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                track.source == 'local'
                                    ? Icons.phone_android
                                    : Icons.cloud,
                                size: 14,
                                color: sourceColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sourceName,
                                style: TextStyle(
                                  color: sourceColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Player Controls - Espace réduit
          Expanded(
            flex: 2, // Réduit de 1 à 2 pour moins d'espace
            child: PlayerControls(expanded: true),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArtPlaceholder(Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(
        Icons.music_note,
        size: 70,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }
}