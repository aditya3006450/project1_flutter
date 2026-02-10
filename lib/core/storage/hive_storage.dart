import 'package:hive_flutter/adapters.dart';
import 'package:project1_flutter/core/storage/local_storage.dart';

class HiveStorage extends LocalStorage {
  HiveStorage._internal();
  static final HiveStorage _instance = HiveStorage._internal();
  factory HiveStorage() {
    return _instance;
  }
  late Box _box;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox("app");
  }

  @override
  T? get<T>(String key) {
    return _box.get(key);
  }

  @override
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> set<T>(String key, T value) async {
    await _box.put(key, value);
  }
}
