import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini_music_app/services/ble_service.dart';
import 'package:mini_music_app/injection_container.dart';
import 'package:mini_music_app/widgets/audio_player_container.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

String songToTitle(String songName) {
  const Map<String, String> songTitleMap = {
    "rollinginthedeep": "Rolling In The Deep",
    "shewillbeloved": "She Will Be Loved",
    "thelessiknowthebetter": "The Less I Know The Better",
    "umbrella": "Umbrella",
    "uptownfunk": "Uptown Funk",
  };
  return songTitleMap[songName] ?? songName;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, String> metadataMap = {};
  String? selectedSong;
  List<String> availableSongs = [];

  List<BluetoothDevice> foundDevices = [];
  BluetoothDevice? selectedDevice;
  bool isScanning = false;
  bool isConnecting = false;
  bool _isDebugging = false;

  Timer? _debugTimer;
  int _debugIndex = 0;
  final List<String> _debugPatterns = ["<000000000000000000000000000000>", "<255255255255255255255255255255>"];

  @override
  void initState() {
    super.initState();
    _loadSongList();
  }

  Future<void> _loadSongList() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifestMap = json.decode(manifestContent) as Map<String, dynamic>;

    setState(() {
      availableSongs = manifestMap.keys.where((key) => key.contains('assets/audio/') && key.endsWith('.mp3')).map((path) => path.split('/').last.replaceAll('.mp3', '')).toList();
    });
  }

  Future<void> _loadMetadata(String songName) async {
    metadataMap.clear();
    try {
      final jsonString = await rootBundle.loadString("assets/data/$songName.json");
      final jsonData = json.decode(jsonString);
      jsonData.forEach((key, value) {
        metadataMap[key] = value.toString();
      });
      setState(() {});
    } catch (e) {
      debugPrint("Error loading metadata: $e");
    }
  }

  Future<void> _startScanForDevices() async {
    setState(() {
      isScanning = true;
      foundDevices.clear();
      selectedDevice = null;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await Future.delayed(const Duration(seconds: 5));
    FlutterBluePlus.stopScan();

    List<ScanResult> results = await FlutterBluePlus.scanResults.first;
    setState(() {
      foundDevices = results.where((r) => r.device.platformName.startsWith("Gloves_BLE")).map((r) => r.device).toSet().toList();
      // foundDevices = results.map((r) => r.device).toSet().toList();
      isScanning = false;
    });
  }

  Future<void> _connectToSelectedDevice() async {
    final bleService = sl<BLEService>();

    if (selectedDevice == null) return;

    setState(() => isConnecting = true);

    bleService.targetDeviceName = selectedDevice!.platformName;
    await bleService.scanAndConnect();

    setState(() => isConnecting = false);
  }

  void _startDebugMode() {
    final bleService = sl<BLEService>();
    _debugIndex = 0;

    _debugTimer?.cancel();
    _debugTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      String pattern = _debugPatterns[_debugIndex % _debugPatterns.length];
      bleService.writeData(pattern);
      _debugIndex++;
    });

    setState(() => _isDebugging = true);
  }

  void _stopDebugMode() {
    _debugTimer?.cancel();
    setState(() => _isDebugging = false);
  }

  @override
  void dispose() {
    _debugTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleService = sl<BLEService>();
    final isConnected = bleService.connectedDevice != null;

    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            metadataMap.isEmpty
                ? const Spacer()
                : Expanded(
                    child: AudioPlayerContainer(
                      audioAssetPath: "audio/$selectedSong.mp3",
                      metadataMap: metadataMap,
                    ),
                  ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedSong,
              hint: const Text("Select song"),
              items: availableSongs.map((song) {
                return DropdownMenuItem(
                  value: song,
                  child: Text(songToTitle(song)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedSong = value);
              },
            ),
            ElevatedButton(
              onPressed: selectedSong != null ? () => _loadMetadata(selectedSong!) : null,
              child: const Text("Load patterns"),
            ),
            const SizedBox(height: 20),
            if (!isConnected) ...[
              if (isScanning)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _startScanForDevices,
                  child: const Text("Scan for devices"),
                ),
              DropdownButton<BluetoothDevice>(
                hint: const Text("Select device"),
                value: selectedDevice,
                onChanged: (device) => setState(() => selectedDevice = device),
                items: foundDevices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text(device.platformName),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: selectedDevice != null && !isConnecting ? _connectToSelectedDevice : null,
                child: isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Connect"),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () async {
                  _stopDebugMode();
                  await bleService.disconnect();
                  setState(() {});
                },
                child: const Text("Disconnect"),
              ),
              ElevatedButton(
                onPressed: _isDebugging ? _stopDebugMode : _startDebugMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDebugging ? Colors.red : Colors.green,
                ),
                child: Text(_isDebugging ? "Stop Debug" : "Start Debug"),
              ),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
