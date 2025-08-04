import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mini_music_app/services/ble_service.dart';
import 'package:mini_music_app/injection_container.dart';
import 'package:mini_music_app/services/logger_service.dart';
import 'package:mini_music_app/widgets/station.dart';

class AudioPlayerContainer extends StatefulWidget {
  final String audioAssetPath; // Path to local MP3 file
  final Map<String, String> metadataMap; // JSON metadata mapping

  const AudioPlayerContainer({
    super.key,
    required this.audioAssetPath,
    required this.metadataMap,
  });

  @override
  AudioPlayerContainerState createState() => AudioPlayerContainerState();
}

class AudioPlayerContainerState extends State<AudioPlayerContainer> {
  final AudioPlayer _audioPlayer = AudioPlayer(); // Ensure a single instance
  bool _isPlaying = false;
  bool _isSeeking = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _lastSentString = "<000000000000000000000000000000>";
  late final BLEService _bleService;
  late final LoggerService _logger;

  @override
  void initState() {
    super.initState();
    _bleService = sl<BLEService>();
    _logger = sl<LoggerService>();

    // Listen for duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    // Listen for position updates
    _audioPlayer.onPositionChanged.listen((position) {
      if (!_isSeeking) {
        setState(() => _position = position);
        _checkAndSendMetadata(position);
      }
    });

    // Reset state when the song ends
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
      });
    });
  }

  /// **Check and send BLE metadata at the correct timestamp**
  void _checkAndSendMetadata(Duration currentPosition) {
    String currentTime = (currentPosition.inMilliseconds / 1000).toStringAsFixed(1);
    String newMetadata = widget.metadataMap[currentTime] ?? "<000000000000000000000000000000>";
    // if (newMetadata == null) {
    //   String newCurrentTime1 = (double.parse(currentTime) + 0.1).toString();
    //   newMetadata = widget.metadataMap[newCurrentTime1];
    //   if (newMetadata == null) {
    //     String newCurrentTime1 = (double.parse(currentTime) - 0.1).toString();
    //     newMetadata = widget.metadataMap[newCurrentTime1];
    //   }
    // }
    if (newMetadata != _lastSentString) {
      setState(() {
        _lastSentString = newMetadata;
      });

      _bleService.writeData(newMetadata);
    }
    _logger.log("'$currentTime': '$newMetadata',");
    // if (widget.metadataMap.containsKey(currentTime)) {
    //   String newMetadata = widget.metadataMap[currentTime]!;
    //   if (newMetadata != _lastSentString) {
    //     setState(() {
    //       _lastSentString = newMetadata;
    //     });
    //     _bleService.writeData(newMetadata);
    //   }
    // }
  }

  /// **Toggle Play/Pause functionality**
  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(AssetSource(widget.audioAssetPath));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  /// **Restart Audio & Reset Everything**
  void _restartAudio() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
      _lastSentString = "<000000000000000000000000000000>";
    });
  }

  /// **Seek to a specific time in the audio**
  void _seekAudio(double value) async {
    setState(() => _isSeeking = true);
    await _audioPlayer.seek(Duration(seconds: value.toInt()));
    setState(() => _isSeeking = false);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// **Format Duration into mm:ss**
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
        // Text(
        //   (_position.inMilliseconds / 1000).toStringAsFixed(1),
        //   style: TextStyle(fontSize: 18),
        // ),
        // const SizedBox(height: 20),
        // Text(
        //   _lastSentString,
        //   style: TextStyle(fontSize: 18),
        // ),
        // const SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Song Progress
              Slider(
                min: 0,
                max: _duration.inSeconds.toDouble(),
                value: _position.inSeconds.toDouble(),
                onChanged: _seekAudio,
              ),

              // Time Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),

              // Controls: Play/Pause & Restart
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
