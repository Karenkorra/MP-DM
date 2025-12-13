import 'package:flutter/material.dart';
import '../models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final bool showSource;
  final bool isPlaying;
  final bool showPlayIcon;
  final bool dense;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const TrackTile({
    Key? key,
    required this.track,
    required this.onTap,
    this.showSource = true,
    this.isPlaying = false,
    this.showPlayIcon = false,
    this.dense = false,
    this.backgroundColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: dense,
        leading: _buildThumbnail(),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isPlaying ? theme.primaryColor : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 12 : 14,
                color: isPlaying ? theme.primaryColor.withOpacity(0.7) : null,
              ),
            ),
            if (showSource) _buildSourceInfo(),
          ],
        ),
        trailing: _buildTrailing(context),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildThumbnail() {
    final size = dense ? 40.0 : 50.0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: track.thumbnailUrl != null && !track.isAsset
              ? Image.network(
            track.thumbnailUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(size);
            },
          )
              : track.isAsset && track.thumbnailUrl != null
              ? Image.asset(
            track.thumbnailUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(size);
            },
          )
              : _buildPlaceholder(size),
        ),
        if (isPlaying)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: track.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.music_note,
        color: track.color,
        size: size * 0.4,
      ),
    );
  }

  Widget _buildSourceInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            track.isLocal ? Icons.phone_android : Icons.cloud,
            size: dense ? 10 : 12,
            color: track.color,
          ),
          const SizedBox(width: 4),
          Text(
            track.sourceName,
            style: TextStyle(
              fontSize: dense ? 10 : 11,
              color: track.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final children = <Widget>[];

    // Ajouter l'icône de lecture si nécessaire
    if (showPlayIcon && isPlaying) {
      children.add(
        Icon(
          Icons.equalizer,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      );
      children.add(const SizedBox(width: 8));
    }

    // Ajouter la durée si disponible
    if (track.duration != null) {
      children.add(
        Text(
          _formatDuration(track.duration!),
          style: TextStyle(
            fontSize: dense ? 11 : 12,
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    // Ajouter l'icône local si c'est une musique locale
    if (track.isLocal) {
      children.add(const SizedBox(width: 8));
      children.add(
        Icon(
          Icons.phone_android,
          size: dense ? 14 : 16,
          color: Colors.green,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}