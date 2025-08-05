import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mini_music_app/services/ble_service.dart';
import 'package:mini_music_app/injection_container.dart';
import 'package:mini_music_app/services/logger_service.dart';
import 'package:mini_music_app/widgets/station.dart';

class AudioPlayerContainer extends StatefulWidget {
  final String audioAssetPath;
  final Map<String, String> metadataMap;

  const AudioPlayerContainer({
    super.key,
    required this.audioAssetPath,
    required this.metadataMap,
  });

  @override
  AudioPlayerContainerState createState() => AudioPlayerContainerState();
}

class AudioPlayerContainerState extends State<AudioPlayerContainer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isSeeking = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _lastSentString = "<000000000000000000000000000000>";
  late final BLEService _bleService;
  late final LoggerService _logger;
  Timer? _logTimer;

  @override
  void initState() {
    super.initState();
    _bleService = sl<BLEService>();
    _logger = sl<LoggerService>();

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (!_isSeeking) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
      });
      _logTimer?.cancel();
    });
  }

  void _startLoggingTimer() {
    _logTimer?.cancel(); // Prevent duplicate timers
    _logTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _logAndSend());
  }

  void _stopLoggingTimer() {
    _logTimer?.cancel();
  }

  bool _isWriting = false;

  Future<void> _logAndSend() async {
    if (_isWriting) return;
    _isWriting = true;

    try {
      final position = await _audioPlayer.getCurrentPosition();
      if (position == null) return;

      final currentTime = (position.inMilliseconds / 1000).toStringAsFixed(1);
      final newMetadata = widget.metadataMap[currentTime] ?? "<000000000000000000000000000000>";

      if (newMetadata != _lastSentString) {
        // setState(() => _lastSentString = newMetadata);
        _lastSentString = newMetadata;
        await _bleService.writeData(newMetadata);
        _logger.log("'$currentTime': '$newMetadata',");
      } else {
        _logger.log("'$currentTime': '$newMetadata',");
      }
    } finally {
      _isWriting = false;
    }
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _stopLoggingTimer();
    } else {
      await _audioPlayer.play(AssetSource(widget.audioAssetPath));
      _startLoggingTimer();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _restartAudio() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);
    _stopLoggingTimer();
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
      _lastSentString = "<000000000000000000000000000000>";
    });
  }

  void _seekAudio(double value) async {
    setState(() => _isSeeking = true);
    await _audioPlayer.seek(Duration(seconds: value.toInt()));
    setState(() => _isSeeking = false);
  }

  @override
  void dispose() {
    _stopLoggingTimer();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Station(data: _lastSentString),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                min: 0,
                max: _duration.inSeconds.toDouble(),
                value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                onChanged: _seekAudio,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    iconSize: 50,
                    color: Colors.blueAccent,
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.replay),
                    iconSize: 40,
                    color: Colors.redAccent,
                    onPressed: _restartAudio,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
