import 'dart:typed_data';
import 'dart:io';
import 'package:path/path.dart' as p;

class SnapshotService {
  void saveSnapshot(Uint8List data, Directory dir) {
    final file = File(p.join(dir.path, 'snapshot_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    file.writeAsBytesSync(data);
  }

  void saveVideo(List<Uint8List> frames, Directory dir) {
    print('[IO] Videoaufnahme derzeit nicht verfügbar (kein FFmpeg).');
  }
}
