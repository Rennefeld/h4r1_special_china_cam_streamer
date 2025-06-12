import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FFmpegHelper {
  static Future<String> prepareExecutable() async {
    final dir = await getTemporaryDirectory();
    final ffmpegPath = '${dir.path}/ffmpeg.exe';

    final file = File(ffmpegPath);
    if (!await file.exists()) {
      final bytes = await rootBundle.load('assets/bin/ffmpeg.exe');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      try {
        await Process.run('icacls', [ffmpegPath, '/grant', '${Platform.environment['USERNAME']}:RX']);
      } catch (_) {}
    }

    return ffmpegPath;
  }
}
