import 'package:hive/hive.dart';

enum ClipType { url, email, phone, code, styledText, plainText }

ClipType detectClipType(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return ClipType.plainText;
  final urlPattern = RegExp(r'^(https?://|www\.)\S+$', caseSensitive: false);
  final emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  final phonePattern = RegExp(r'^\+?[0-9()\-\s]{7,20}$');
  final codePattern = RegExp(r'[{};]|=>|function\s|const\s|class\s|def\s|import\s');
  if (urlPattern.hasMatch(trimmed)) return ClipType.url;
  if (emailPattern.hasMatch(trimmed)) return ClipType.email;
  if (phonePattern.hasMatch(trimmed)) return ClipType.phone;
  if (codePattern.hasMatch(trimmed) || trimmed.contains('\n  ')) return ClipType.code;
  return ClipType.plainText;
}

class ClipEntry extends HiveObject {
  String id;
  String text;
  DateTime createdAt;
  int typeIndex;
  bool pinned;

  /// Manual drag-to-reorder position within its pinned/unpinned group.
  /// Lower sorts first. Defaults to `createdAt` millis so existing/new
  /// entries start in newest-first order until the user drags one.
  double sortOrder;

  ClipEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.typeIndex,
    this.pinned = false,
    double? sortOrder,
  }) : sortOrder = sortOrder ?? -createdAt.millisecondsSinceEpoch.toDouble();

  ClipType get type => ClipType.values[typeIndex];
}

class ClipEntryAdapter extends TypeAdapter<ClipEntry> {
  @override
  final int typeId = 0;

  @override
  ClipEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final createdAt = fields[2] as DateTime;
    return ClipEntry(
      id: fields[0] as String,
      text: fields[1] as String,
      createdAt: createdAt,
      typeIndex: fields[3] as int,
      pinned: fields[4] as bool,
      sortOrder: fields[5] as double? ?? -createdAt.millisecondsSinceEpoch.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ClipEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.pinned)
      ..writeByte(5)
      ..write(obj.sortOrder);
  }
}
