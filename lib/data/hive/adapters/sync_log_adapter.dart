import 'package:hive/hive.dart';
import '../../models/sync_log.dart';

class SyncLogAdapter extends TypeAdapter<SyncLog> {
  @override
  final int typeId = 3;

  @override
  SyncLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncLog(
      id: fields[0] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      finishedAt: fields[2] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[2] as int)
          : null,
      trigger: fields[3] as String,
      smsScanned: fields[4] as int? ?? 0,
      newSmsSaved: fields[5] as int? ?? 0,
      pendingFetched: fields[6] as int? ?? 0,
      matchedCount: fields[7] as int? ?? 0,
      approvedCount: fields[8] as int? ?? 0,
      failedCount: fields[9] as int? ?? 0,
      error: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncLog obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startedAt.millisecondsSinceEpoch)
      ..writeByte(2)
      ..write(obj.finishedAt?.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.trigger)
      ..writeByte(4)
      ..write(obj.smsScanned)
      ..writeByte(5)
      ..write(obj.newSmsSaved)
      ..writeByte(6)
      ..write(obj.pendingFetched)
      ..writeByte(7)
      ..write(obj.matchedCount)
      ..writeByte(8)
      ..write(obj.approvedCount)
      ..writeByte(9)
      ..write(obj.failedCount)
      ..writeByte(10)
      ..write(obj.error);
  }
}
