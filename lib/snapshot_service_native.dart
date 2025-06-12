import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'ffmpeg_helper.dart';

class SnapshotService {
  Future<void> saveSnapshot(Uint8List bytes, Directory dir) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Snapshot speichern...',
      fileName: 'snapshot_${DateTime.now().millisecondsSinceEpoch}.jpg',
      type: FileType.custom,
      allowedExtensions: ['jpg'],
    );
    if (path == null) return;
    await File(path).writeAsBytes(bytes);
    print('[Snapshot] Saved to $path');
  }

  Future<void> saveVideo(List<Uint8List> frames, Directory dir) async {
    print('[DEBUG] Anzahl Frames: ${frames.length}');
    print('[DEBUG] Zielverzeichnis: ${dir.path}');

    if (frames.isEmpty) {
      print('[Recording] Keine Frames zum Speichern.');
      return;
    }

    final tmpFrameDir = Directory('${dir.path}/frames_temp');
    if (!await tmpFrameDir.exists()) await tmpFrameDir.create(recursive: true);

    print('[Recording] Schreibe ${frames.length} Frames...');

    for (int i = 0; i < frames.length; i++) {
      final filename = 'frame_${i.toString().padLeft(5, '0')}.jpg';
      final file = File('${tmpFrameDir.path}/$filename');
      await file.writeAsBytes(frames[i], flush: true);

      final exists = await file.exists();
      final size = await file.length();
      print('[DEBUG] Frame $i: ${file.path} (${exists ? 'OK' : 'FEHLT'}, $size bytes)');
    }

    final testFile = File('${tmpFrameDir.path}/frame_00000.jpg');
    if (!await testFile.exists()) {
      print('[FEHLER] frame_00000.jpg fehlt – FFmpeg wird NICHT gestartet.');
      return;
    }

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Video speichern...',
      fileName: 'recording_${DateTime.now().millisecondsSinceEpoch}.mp4',
      type: FileType.custom,
      allowedExtensions: ['mp4'],
    );
    if (outputPath == null) return;

    final existing = File(outputPath);
    if (await existing.exists()) {
      await existing.delete(); // alte Datei löschen, um Anhängen zu verhindern
    }

    final ffmpegPath = await FFmpegHelper.prepareExecutable();

    print('[FFmpeg] Starte Encoding...');
    final result = await Process.run(ffmpegPath, [
      '-y', // erzwingt Überschreiben
      '-framerate', '25',
      '-i', '${tmpFrameDir.path}/frame_%05d.jpg',
      '-c:v', 'libx264',
      '-pix_fmt', 'yuv420p',
      outputPath,
    ]);

    if (result.exitCode == 0) {
      print('[Recording] Video gespeichert: $outputPath');
    } else {
      print('[Recording] FFmpeg Fehler:\n${result.stderr}');
    }

    await tmpFrameDir.delete(recursive: true);
  }
}
