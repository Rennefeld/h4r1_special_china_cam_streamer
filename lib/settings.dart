import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  String _camIp;
  int _camPort;
  int _width;
  int _height;
  bool _grayscale;
  double _brightness;
  bool _flipH;
  bool _flipV;
  bool _rotate;

  Settings({
    required String camIp,
    required int camPort,
    required int width,
    required int height,
    bool grayscale = false,
    double brightness = 1.0,
    bool flipHorizontal = false,
    bool flipVertical = false,
    bool rotate = false,
  })  : _camIp = camIp,
        _camPort = camPort,
        _width = width,
        _height = height,
        _grayscale = grayscale,
        _brightness = brightness,
        _flipH = flipHorizontal,
        _flipV = flipVertical,
        _rotate = rotate;

  // Keys
  static const _camIpKey = 'camIp';
  static const _camPortKey = 'camPort';
  static const _widthKey = 'width';
  static const _heightKey = 'height';
  static const _grayKey = 'grayscale';
  static const _brightKey = 'brightness';
  static const _flipHKey = 'flipH';
  static const _flipVKey = 'flipV';
  static const _rotateKey = 'rotate';

  // Getters and setters
  String get camIp => _camIp;
  set camIp(String value) {
    _camIp = value;
    _save();
    notifyListeners();
  }

  int get camPort => _camPort;
  set camPort(int value) {
    _camPort = value;
    _save();
    notifyListeners();
  }

  int get width => _width;
  set width(int value) {
    _width = value;
    _save();
    notifyListeners();
  }

  int get height => _height;
  set height(int value) {
    _height = value;
    _save();
    notifyListeners();
  }

  bool get grayscale => _grayscale;
  set grayscale(bool value) {
    _grayscale = value;
    _save();
    notifyListeners();
  }

  double get brightness => _brightness;
  set brightness(double value) {
    _brightness = value;
    _save();
    notifyListeners();
  }

  bool get flipH => _flipH;
  set flipH(bool value) {
    _flipH = value;
    _save();
    notifyListeners();
  }

  bool get flipV => _flipV;
  set flipV(bool value) {
    _flipV = value;
    _save();
    notifyListeners();
  }

  bool get rotate => _rotate;
  set rotate(bool value) {
    _rotate = value;
    _save();
    notifyListeners();
  }

  static Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings(
      camIp: prefs.getString(_camIpKey) ?? '192.168.4.153',
      camPort: prefs.getInt(_camPortKey) ?? 8080,
      width: prefs.getInt(_widthKey) ?? 640,
      height: prefs.getInt(_heightKey) ?? 480,
      grayscale: prefs.getBool(_grayKey) ?? false,
      brightness: prefs.getDouble(_brightKey) ?? 1.0,
      flipHorizontal: prefs.getBool(_flipHKey) ?? false,
      flipVertical: prefs.getBool(_flipVKey) ?? false,
      rotate: prefs.getBool(_rotateKey) ?? false,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_camIpKey, _camIp);
    await prefs.setInt(_camPortKey, _camPort);
    await prefs.setInt(_widthKey, _width);
    await prefs.setInt(_heightKey, _height);
    await prefs.setBool(_grayKey, _grayscale);
    await prefs.setDouble(_brightKey, _brightness);
    await prefs.setBool(_flipHKey, _flipH);
    await prefs.setBool(_flipVKey, _flipV);
    await prefs.setBool(_rotateKey, _rotate);
  }

  void update({
    String? camIp,
    int? camPort,
    int? width,
    int? height,
    bool? grayscale,
    double? brightness,
    bool? flipHorizontal,
    bool? flipVertical,
    bool? rotate,
  }) {
    if (camIp != null) _camIp = camIp;
    if (camPort != null) _camPort = camPort;
    if (width != null) _width = width;
    if (height != null) _height = height;
    if (grayscale != null) _grayscale = grayscale;
    if (brightness != null) _brightness = brightness;
    if (flipHorizontal != null) _flipH = flipHorizontal;
    if (flipVertical != null) _flipV = flipVertical;
    if (rotate != null) _rotate = rotate;
    _save();
    notifyListeners();
  }
}
