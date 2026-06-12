import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  static const String _appBoxName = 'efordo_app';

  Future<Box> get _appBox async => await Hive.openBox(_appBoxName);

  Future<void> saveString(String key, String value) async {
    final box = await _appBox;
    await box.put(key, value);
  }

  Future<String?> getString(String key) async {
    final box = await _appBox;
    return box.get(key) as String?;
  }

  Future<void> saveBool(String key, bool value) async {
    final box = await _appBox;
    await box.put(key, value);
  }

  Future<bool?> getBool(String key) async {
    final box = await _appBox;
    return box.get(key) as bool?;
  }

  Future<void> saveInt(String key, int value) async {
    final box = await _appBox;
    await box.put(key, value);
  }

  Future<int?> getInt(String key) async {
    final box = await _appBox;
    return box.get(key) as int?;
  }

  Future<void> remove(String key) async {
    final box = await _appBox;
    await box.delete(key);
  }

  Future<void> clear() async {
    final box = await _appBox;
    await box.clear();
  }
}
