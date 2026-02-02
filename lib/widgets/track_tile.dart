import 'package:flutter/material.dart';
import '../models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isPlaying;

  const TrackTile({
    Key? key,
    required this.track,
    required this.onTap,
    this.onLongPress,
    this.isPlaying = false,
  }) : super(key: key);

  Color _getSourceColor(String source) {
    switch (source) {
      case 'soundcloud':
        return const Color(0xFFff3300);
      case 'audius':
        return const Color(0xFF8B5CF6);
      case 'jamendo':
        return const Color(0xFF00A2FF);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'local':
        return const Color(0xFF9C27B0);
      case 'device':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'soundcloud':
        return Icons.cloud;
      case 'audius':
        return Icons.music_note;
      case 'jamendo':
        return Icons.library_music;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'local':
        return Icons.album;
      case 'device':
        return Icons.phone_android;
      default:
        return Icons.music_note;
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sourceColor = _getSourceColor(track.source);
    final sourceIcon = _getSourceIcon(track.source);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sourceColor.withOpacity(0.1),
            Colors.grey[900]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? sourceColor.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isPlaying ? 2 : 1,
        ),
        boxShadow: isPlaying
            ? [
          BoxShadow(
            color: sourceColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail ou icône
                _buildThumbnail(sourceColor, sourceIcon),
                const SizedBox(width: 12),

                // Informations de la piste
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        track.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPlaying ? sourceColor : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Artiste
                      Text(
                        track.artist,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Métadonnées (source, genre, BPM)
                      Row(
                        children: [
                          // Source badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: sourceColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: sourceColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  sourceIcon,
                                  size: 12,
                                  color: sourceColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  track.source.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: sourceColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Genre (si disponible)
                          if (track.genre != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                track.genre!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ],

                          // BPM (si disponible)
                          if (track.bpm != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.speed,
                                    size: 10,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${track.bpm}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Durée et indicateur de lecture
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Indicateur de lecture
                    if (isPlaying)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: sourceColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: sourceColor,
                          size: 20,
                        ),
                      )
                    else
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                    const SizedBox(height: 4),

                    // Durée
                    Text(
                      _formatDuration(track.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Color sourceColor, IconData sourceIcon) {
    if (track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[800],
          ),
          child: Image.network(
            track.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderThumbnail(sourceColor, sourceIcon);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildPlaceholderThumbnail(sourceColor, sourceIcon);
            },
          ),
        ),
      );
    }

    return _buildPlaceholderThumbnail(sourceColor, sourceIcon);
  }

  Widget _buildPlaceholderThumbnail(Color sourceColor, IconData sourceIcon) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sourceColor.withOpacity(0.7),
            sourceColor.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        sourceIcon,
        color: Colors.white.withOpacity(0.8),
        size: 30,
      ),
    );
  }
}