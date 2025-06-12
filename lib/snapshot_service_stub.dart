import 'dart:typed_data';
import 'dart:io';

class SnapshotService {
  void saveSnapshot(Uint8List data, Directory dir) {
    print('[WEB] Snapshot nicht unterstützt.');
  }

  void saveVideo(List<Uint8List> frames, Directory dir) {
    print('[WEB] Videoaufnahme nicht unterstützt.');
  }
}
