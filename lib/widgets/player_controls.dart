import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../viewmodels/player_viewmodel.dart';

class PlayerControls extends StatelessWidget {
  final bool expanded;

  const PlayerControls({
    Key? key,
    this.expanded = false,
  }) : super(key: key);

  // Helper pour obtenir la couleur basée sur la source
  Color _getSourceColor(String? source) {
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

  Widget _buildPlaceholder(Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }

  Widget _buildThumbnail(Track? track) {
    final sourceColor = _getSourceColor(track?.source);
    final size = 40.0;

    // Si le track a une thumbnail URL, essayer de l'afficher
    if (track?.thumbnailUrl != null && track!.thumbnailUrl!.isNotEmpty) {
      return Image.network(
        track.thumbnailUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(sourceColor);
        },
      );
    }

    // Sinon, afficher le placeholder
    return _buildPlaceholder(sourceColor);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlayerViewModel>();
    final track = viewModel.currentTrack;

    if (track == null && !expanded) {
      return Container();
    }

    if (!expanded) {
      final sourceColor = _getSourceColor(track?.source);

      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de progression
            ProgressBar(
              currentPosition: viewModel.currentPosition,
              duration: viewModel.currentDuration,
              onSeek: (position) => viewModel.seek(position),
              progressColor: sourceColor,
            ),

            // Informations et contrôles
            ListTile(
              leading: _buildThumbnail(track),
              title: Text(
                track?.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                track?.artist ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 24,
                    ),
                    onPressed: () {
                      if (viewModel.isPlaying) {
                        viewModel.pause();
                      } else {
                        viewModel.resume();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 24),
                    onPressed: viewModel.hasNext ? viewModel.next : null,
                  ),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, '/player');
              },
            ),
          ],
        ),
      );
    }

    // MODIFIÉ : Version avec espacements réduits
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), // Padding réduit
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Aligné en haut
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Informations de la piste - avec espacements réduits
          if (track != null) ...[
            Column(
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    fontSize: 22, // Légèrement réduit
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4), // Réduit de 8 à 4
                Text(
                  track.artist,
                  style: TextStyle(
                    fontSize: 16, // Réduit de 18 à 16
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12), // Réduit de 20 à 12
              ],
            ),
          ],

          // Barre de progression avec temps
          ProgressBar(
            currentPosition: viewModel.currentPosition,
            duration: viewModel.currentDuration,
            onSeek: (position) => viewModel.seek(position),
            progressColor: Theme.of(context).primaryColor,
          ),

          // Contrôles de lecture principaux avec espacements réduits
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8), // Réduit de 20 à 8
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: viewModel.isShuffled
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                  onPressed: viewModel.shuffle,
                ),

                // Previous
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 32, // Réduit de 36 à 32
                  onPressed: viewModel.hasPrevious ? viewModel.previous : null,
                ),

                // Play/Pause (bouton principal)
                IconButton(
                  icon: Icon(
                    viewModel.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 56, // Réduit de 60 à 56
                  ),
                  onPressed: () {
                    if (viewModel.isPlaying) {
                      viewModel.pause();
                    } else {
                      viewModel.resume();
                    }
                  },
                ),

                // Next
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 32, // Réduit de 36 à 32
                  onPressed: viewModel.hasNext ? viewModel.next : null,
                ),

                // Repeat
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: viewModel.isRepeating
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                  onPressed: viewModel.toggleRepeat,
                ),
              ],
            ),
          ),

          // Contrôle Stop avec espacement réduit
          IconButton(
            icon: const Icon(Icons.stop),
            iconSize: 32, // Réduit de 36 à 32
            onPressed: viewModel.stop,
          ),
        ],
      ),
    );
  }
}


// Widget ProgressBar (inchangé)
class ProgressBar extends StatefulWidget {
  final Duration? currentPosition;
  final Duration? duration;
  final Function(Duration) onSeek;
  final Color? progressColor;
  final Color? backgroundColor;

  const ProgressBar({
    Key? key,
    required this.currentPosition,
    required this.duration,
    required this.onSeek,
    this.progressColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  bool _isDragging = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.progressColor ?? Theme.of(context).primaryColor;
    final backgroundColor = widget.backgroundColor ?? Colors.grey[700];

    final duration = widget.duration ?? Duration.zero;
    final currentPosition = widget.currentPosition ?? Duration.zero;

    final value = _isDragging
        ? (_dragValue ?? 0.0)
        : (duration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / duration.inMilliseconds
        : 0.0);

    final positionText = _formatDuration(currentPosition);
    final durationText = _formatDuration(duration);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slider pour la progression
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: progressColor,
            inactiveTrackColor: backgroundColor,
            trackHeight: 3,
            thumbColor: progressColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayColor: progressColor.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: (newValue) {
              setState(() {
                _isDragging = true;
                _dragValue = newValue;
              });
            },
            onChangeEnd: (newValue) {
              final newPosition = Duration(
                milliseconds: (duration.inMilliseconds * newValue).round(),
              );
              widget.onSeek(newPosition);
              setState(() {
                _isDragging = false;
                _dragValue = null;
              });
            },
          ),
        ),

        // Temps écoulé / total
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                positionText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                durationText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}