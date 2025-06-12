import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'settings.dart';

typedef FrameCallback = void Function(Uint8List frame);

class UdpStreamReceiver extends ChangeNotifier {
  final String camIp;
  final int camPort;
  final ValueNotifier<Uint8List?> frame = ValueNotifier(null);
  RawDatagramSocket? _socket;
  Timer? _keepAliveTimer;
  FrameCallback? onFrame;

  final Settings settings;

  UdpStreamReceiver(this.settings)
      : camIp = settings.camIp,
        camPort = 8080;

  Future<void> start() async {
    await _bindSocket();
  }

  void stop() {
    _keepAliveTimer?.cancel();
    _socket?.close();
    _socket = null;
    _imageBuffer.clear();
    _collecting = false;
    debugPrint('[UdpStreamReceiver] UDP stream stopped.');
  }

  Future<void> _bindSocket() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      debugPrint('[UdpStreamReceiver] Listening on ${_socket!.address.address}:${_socket!.port}');
      _socket!.listen(_onEvent);
      _keepAliveTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _sendKeepAlive(),
      );
    } catch (e) {
      debugPrint('[UdpStreamReceiver] Failed to bind socket: $e');
    }
  }

  void _sendKeepAlive() {
    _socket?.send(
      Uint8List.fromList([0x42, 0x76]),
      InternetAddress(camIp),
      camPort,
    );
    debugPrint('[KA] sent Bv to $camIp:$camPort');
  }

  List<int> _imageBuffer = [];
  bool _collecting = false;
  int _packetCounter = 0;

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;

    final data = datagram.data;
    _packetCounter++;

    if (data.length <= 8) {
      debugPrint('[UDP $_packetCounter] short packet, ignored');
      return;
    }

    final payload = data.sublist(8);

    if (payload.length >= 2 && payload[0] == 0xFF && payload[1] == 0xD8) {
      _imageBuffer = List<int>.from(payload);
      _collecting = true;
    } else if (_collecting) {
      _imageBuffer.addAll(payload);
    }

    if (_collecting && _containsEoi(payload)) {
      int eoiIndex = _findEoiIndex(_imageBuffer);
      if (eoiIndex != -1) {
        try {
          final end = (eoiIndex + 2 <= _imageBuffer.length) ? eoiIndex + 2 : _imageBuffer.length;
          final safeEnd = (_imageBuffer.length > eoiIndex + 1) ? eoiIndex + 2 : _imageBuffer.length;
          final jpeg = Uint8List.fromList(_imageBuffer.sublist(0, safeEnd));
          frame.value = jpeg;
          onFrame?.call(jpeg);
        } catch (e) {
          debugPrint('[UDP $_packetCounter] JPEG decode failed: $e');
        }
        _imageBuffer.clear();
        _collecting = false;
      }
    }
  }

  bool _containsEoi(Uint8List data) {
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 0xFF && data[i + 1] == 0xD9) return true;
    }
    return false;
  }

  int _findEoiIndex(List<int> data) {
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 0xFF && data[i + 1] == 0xD9) return i;
    }
    return -1;
  }

  @override
  void dispose() {
    _keepAliveTimer?.cancel();
    _socket?.close();
    frame.dispose();
    super.dispose();
  }
}
