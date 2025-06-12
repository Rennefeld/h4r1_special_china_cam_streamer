import 'dart:typed_data';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class SnapshotService {
  void saveSnapshot(Uint8List data, Directory dir) {
    final file = File(p.join(dir.path, 'snapshot_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    file.writeAsBytesSync(data);
  }

  void saveVideo(List<Uint8List> frames, Directory dir) async {
    final tempDir = Directory(p.join(dir.path, 'frames'));
    if (!tempDir.existsSync()) tempDir.createSync();

    for (int i = 0; i < frames.length; i++) {
      final imgFile = File(p.join(tempDir.path, 'frame_${i.toString().padLeft(4, '0')}.jpg'));
      imgFile.writeAsBytesSync(frames[i]);
    }

    final outPath = p.join(dir.path, 'recording_${DateTime.now().millisecondsSinceEpoch}.mp4');
    final cmd = '-framerate 10 -i ${p.join(tempDir.path, 'frame_%04d.jpg')} -c:v libx264 -pix_fmt yuv420p "$outPath"';
    await FFmpegKit.execute(cmd);

    tempDir.deleteSync(recursive: true);
  }
}
