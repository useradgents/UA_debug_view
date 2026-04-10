/// Provides read/delete access to a custom key-value storage
/// (e.g. FlutterSecureStorage, Hive, etc.) for [StorageModule].
class DebugStorageProvider {
  /// Human-readable name shown in the debug panel.
  final String name;

  /// Reads all key-value pairs from the storage.
  final Future<Map<String, String>> Function() read;

  /// Deletes a single entry by key. Optional — omit to make the storage read-only.
  final Future<void> Function(String key)? delete;

  const DebugStorageProvider({
    required this.name,
    required this.read,
    this.delete,
  });
}
