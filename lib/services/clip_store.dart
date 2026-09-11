import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/clip_entry.dart';
import 'keyboard_bridge.dart';

/// Local-only clipboard history store. Backed by Hive so the same box file
/// can later be pointed at an App Group container (iOS) or shared storage
/// (Android) for the keyboard extension to read directly.
class ClipStore {
  static const boxName = 'clips';
  static const _uuid = Uuid();
  late Box<ClipEntry> _box;

  static final ClipStore instance = ClipStore._();
  ClipStore._();

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClipEntryAdapter());
    }
    _box = await Hive.openBox<ClipEntry>(boxName);
  }

  List<ClipEntry> all() {
    final items = _box.values.toList();
    items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return items;
  }

  /// Applies a drag-to-reorder within the given (already-sorted) list of
  /// visible entries: `from`/`to` are indices into that list. `sortOrder` is
  /// mutated in memory immediately (so the very next `all()` call — e.g. the
  /// widget rebuild that follows `setState` — already reflects the new
  /// order), while the Hive write and keyboard sync happen in the
  /// background. Only touches entries within the same pinned/unpinned group
  /// as `visible`, so that grouping (handled in `all()`) is never disturbed.
  void reorder(List<ClipEntry> visible, int from, int to) {
    if (from == to) return;
    final moved = visible[from];
    final reordered = List<ClipEntry>.from(visible)
      ..removeAt(from)
      ..insert(to, moved);
    for (var i = 0; i < reordered.length; i++) {
      reordered[i].sortOrder = i.toDouble();
    }
    Future.wait(reordered.map((e) => e.save())).then((_) => KeyboardBridge.sync(all()));
  }

  Future<ClipEntry> add(String text) async {
    final entry = ClipEntry(
      id: _uuid.v4(),
      text: text,
      createdAt: DateTime.now(),
      typeIndex: detectClipType(text).index,
    );
    await _box.put(entry.id, entry);
    await KeyboardBridge.sync(all());
    return entry;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await KeyboardBridge.sync(all());
  }

  Future<void> togglePin(String id) async {
    final entry = _box.get(id);
    if (entry == null) return;
    entry.pinned = !entry.pinned;
    await entry.save();
    await KeyboardBridge.sync(all());
  }

  Future<void> clearUnpinned() async {
    final toDelete = _box.values.where((e) => !e.pinned).map((e) => e.id).toList();
    await _box.deleteAll(toDelete);
    await KeyboardBridge.sync(all());
  }

  /// Drops unpinned clips older than two hours. Backs the "Auto-clear after
  /// 2 hours" toggle on the Sync & Privacy screen.
  Future<void> purgeOlderThanTwoHours() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 2));
    final toDelete = _box.values
        .where((e) => !e.pinned && e.createdAt.isBefore(cutoff))
        .map((e) => e.id)
        .toList();
    if (toDelete.isEmpty) return;
    await _box.deleteAll(toDelete);
    await KeyboardBridge.sync(all());
  }
}
