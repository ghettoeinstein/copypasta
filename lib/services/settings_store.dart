import 'package:hive_flutter/hive_flutter.dart';

/// Local-only toggles shown on the Sync & Privacy screen. There is no real
/// multi-device sync yet — these persist the user's stated preferences so
/// the app is ready to honor them once device pairing exists, and
/// [autoClearAfterTwoHours] already drives real cleanup via [ClipStore].
class SettingsStore {
  static const boxName = 'settings';
  static const _shareAcrossDevicesKey = 'shareAcrossDevices';
  static const _includeImagesKey = 'includeImages';
  static const _autoClearKey = 'autoClearAfterTwoHours';

  late Box _box;

  static final SettingsStore instance = SettingsStore._();
  SettingsStore._();

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  bool get shareAcrossDevices => _box.get(_shareAcrossDevicesKey, defaultValue: true) as bool;
  bool get includeImages => _box.get(_includeImagesKey, defaultValue: true) as bool;
  bool get autoClearAfterTwoHours => _box.get(_autoClearKey, defaultValue: false) as bool;

  Future<void> setShareAcrossDevices(bool value) => _box.put(_shareAcrossDevicesKey, value);
  Future<void> setIncludeImages(bool value) => _box.put(_includeImagesKey, value);
  Future<void> setAutoClearAfterTwoHours(bool value) => _box.put(_autoClearKey, value);
}
