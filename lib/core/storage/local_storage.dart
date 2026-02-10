abstract class LocalStorage {
  Future<void> init();
  T? get<T>(String key);
  Future<void> set<T>(String key, T value);
  Future<void> remove(String key);
}
