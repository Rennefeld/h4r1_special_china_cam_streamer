import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'services/log_service.dart';
import 'snapshot_service.dart';
import 'udp_stream_receiver.dart';
import 'settings.dart';
import 'settings_page.dart';
import 'frame_processor.dart';
import 'face_detector_service.dart'; // <--- NEU

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogService.init();
  final settings = await Settings.load();
  runApp(MyApp(settings));
}

class MyApp extends StatelessWidget {
  final Settings settings;
  const MyApp(this.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settings,
      child: const CamApp(),
    );
  }
}

class CamApp extends StatelessWidget {
  const CamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CamStreamPage(),
    );
  }
}

class CamStreamPage extends StatefulWidget {
  const CamStreamPage({super.key});

  @override
  State<CamStreamPage> createState() => _CamStreamPageState();
}

class _CamStreamPageState extends State<CamStreamPage> {
  final ValueNotifier<Uint8List?> _frameNotifier = ValueNotifier(null);
  late final SnapshotService _snapshotService;
  late UdpStreamReceiver _receiver;
  Directory? _storageDir;
  bool _recording = false;
  final List<Uint8List> _recordedFrames = [];
  late Settings _settings;
  late FaceDetectorService _faceDetectorService; // <--- NEU

  DateTime _lastFrameTime = DateTime.now();
  Timer? _timeoutTimer;
  Timer? _fpsTimer;
  int _frameCounter = 0;
  int _fps = 0;
  bool _processing = false; // <--- Neu für async-Schutz

  @override
  void initState() {
    super.initState();
    _snapshotService = SnapshotService();
    _faceDetectorService = FaceDetectorService(); // <--- NEU
    _initStorage();
    _settings = context.read<Settings>();
    _settings.addListener(_restartStream);
    _startUdpStream();
    _startTimeoutWatchdog();
    _startFpsCounter();
  }

  void _initStorage() async {
    _storageDir = await getApplicationDocumentsDirectory();
    debugPrint('[App] Storage directory: ${_storageDir!.path}');
  }

  void _startTimeoutWatchdog() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (DateTime.now().difference(_lastFrameTime).inSeconds > 3) {
        debugPrint('[Watchdog] Timeout – reconnecting');
        _restartStream();
      }
    });
  }

  void _startFpsCounter() {
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _fps = _frameCounter;
        _frameCounter = 0;
      });
    });
  }

  void _restartStream() {
    _receiver.stop();
    _startUdpStream();
  }

  void _startUdpStream() {
    _receiver = UdpStreamReceiver(_settings);
    _receiver.onFrame = (frame) async {
      if (_processing) return; // Überlauf verhindern
      _processing = true;
      try {
        final processed = await compute(_processFrame, {
          'frame': frame,
          'rotate': _settings.rotate,
          'flipH': _settings.flipH,
          'flipV': _settings.flipV,
          'grayscale': false,
        });
        // Gesichtserkennung als letzten Schritt
        final marked = await _faceDetectorService.markFaces(processed);

        _lastFrameTime = DateTime.now();
        _frameCounter++;

        if (_recording) {
          debugPrint('[Recording] Frame aufgenommen (${marked.length} bytes)');
          _recordedFrames.add(Uint8List.fromList(marked));
        }

        _frameNotifier.value = marked;
      } catch (e) {
        debugPrint('[Frame] Error during processing: $e');
      } finally {
        _processing = false;
      }
    };
    _receiver.start();
    debugPrint('[Stream] UDP stream started');
  }

  static Uint8List _processFrame(Map<String, dynamic> args) {
    final frame = args['frame'] as Uint8List;
    final processor = FrameProcessor(
      rotate90: args['rotate'] ?? false,
      flipH: args['flipH'] ?? false,
      flipV: args['flipV'] ?? false,
      grayscale: args['grayscale'] ?? false,
    );

    if (frame.isEmpty || frame.length < 100) {
      throw Exception('Ungültiger Frame empfangen (${frame.length} bytes)');
    }

    return processor.process(frame);
  }

  void _toggleRecording() {
    setState(() => _recording = !_recording);
    debugPrint('[Recording] Aufnahme ${_recording ? "gestartet" : "gestoppt"}');

    if (!_recording && _storageDir != null) {
      debugPrint('[Recording] Anzahl aufgezeichneter Frames: ${_recordedFrames.length}');
      if (_recordedFrames.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine gültigen Frames aufgezeichnet.')),
        );
        return;
      }

      final framesCopy = List<Uint8List>.from(_recordedFrames);
      _recordedFrames.clear(); // ← VOR dem Speichern
      _snapshotService.saveVideo(framesCopy, _storageDir!);
    }
  }

  void _takeSnapshot() {
    final frame = _frameNotifier.value;
    if (frame != null && _storageDir != null) {
      _snapshotService.saveSnapshot(frame, _storageDir!);
      debugPrint('[Snapshot] Saved to ${_storageDir!.path}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot saved')),
      );
    }
  }

  @override
  void dispose() {
    _receiver.stop();
    _timeoutTimer?.cancel();
    _fpsTimer?.cancel();
    _frameNotifier.dispose();
    _settings.removeListener(_restartStream);
    _faceDetectorService.dispose(); // <--- NEU
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamLost = DateTime.now().difference(_lastFrameTime).inSeconds > 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('H4R1 Cam Stream'),
        actions: [
          Center(
            child: Text(
              _recording ? 'FPS: $_fps ● REC ${_recordedFrames.length}' : 'FPS: $_fps',
              style: TextStyle(
                fontSize: 16,
                color: _recording ? Colors.redAccent : Colors.white,
                fontWeight: _recording ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ToggleButtons(
              isSelected: [_settings.rotate, _settings.flipH, _settings.flipV],
              onPressed: (index) {
                setState(() {
                  switch (index) {
                    case 0: _settings.rotate = !_settings.rotate; break;
                    case 1: _settings.flipH = !_settings.flipH; break;
                    case 2: _settings.flipV = !_settings.flipV; break;
                  }
                  _settings.notifyListeners();
                });
              },
              children: const [
                Icon(Icons.rotate_90_degrees_ccw),
                Icon(Icons.swap_horiz),
                Icon(Icons.swap_vert),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: ValueListenableBuilder<Uint8List?>(
                      valueListenable: _frameNotifier,
                      builder: (context, frame, _) {
                        return frame == null
                            ? const SizedBox.shrink()
                            : Image.memory(frame, gaplessPlayback: true, filterQuality: FilterQuality.low);
                      },
                    ),
                  ),
                  if (_frameNotifier.value == null || streamLost)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.signal_wifi_off, size: 64, color: Colors.redAccent),
                          SizedBox(height: 10),
                          Text('Stream verloren...', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'snapshotBtn',
            onPressed: _takeSnapshot,
            tooltip: 'Snapshot',
            child: const Icon(Icons.camera),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'recordBtn',
            onPressed: _toggleRecording,
            tooltip: 'Record',
            child: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
          ),
        ],
      ),
    );
  }
}
