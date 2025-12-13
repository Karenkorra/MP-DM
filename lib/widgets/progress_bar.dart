import 'package:flutter/material.dart';
import 'dart:async';

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
      children: [
        // Slider pour la progression
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: progressColor,
            inactiveTrackColor: backgroundColor,
            trackHeight: 4,
            thumbColor: progressColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayColor: progressColor.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                durationText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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