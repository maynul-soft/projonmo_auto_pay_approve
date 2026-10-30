import 'package:hive/hive.dart';
import '../../models/app_state.dart';

class AppStateAdapter extends TypeAdapter<AppState> {
  @override
  final int typeId = 2;

  @override
  AppState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppState(
      lastSmsReadAt: fields[0] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[0] as int)
          : null,
      lastSmsTimestampProcessed: fields[1] as int? ?? 0,
      lastSyncAt: fields[2] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[2] as int)
          : null,
      lastSyncStatus: fields[3] as String?,
      lastSyncMessage: fields[4] as String?,
      pendingApiUrl: fields[5] as String?,
      approveApiUrl: fields[6] as String?,
      baseUrl: fields[7] as String?,
      loginPath: fields[8] as String?,
      syncIntervalMinutes: fields[9] as int? ?? 5,
      strictAmountCheck: fields[10] as bool? ?? true,
      autoApprove: fields[11] as bool? ?? true,
      senderIds: (fields[12] as List?)?.cast<String>() ??
          const ['bKash', 'NAGAD', '16167', '16216'],
      initialScanDays: fields[13] as int? ?? 2,
      allowForceApprove: fields[14] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AppState obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.lastSmsReadAt?.millisecondsSinceEpoch)
      ..writeByte(1)
      ..write(obj.lastSmsTimestampProcessed)
      ..writeByte(2)
      ..write(obj.lastSyncAt?.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.lastSyncStatus)
      ..writeByte(4)
      ..write(obj.lastSyncMessage)
      ..writeByte(5)
      ..write(obj.pendingApiUrl)
      ..writeByte(6)
      ..write(obj.approveApiUrl)
      ..writeByte(7)
      ..write(obj.baseUrl)
      ..writeByte(8)
      ..write(obj.loginPath)
      ..writeByte(9)
      ..write(obj.syncIntervalMinutes)
      ..writeByte(10)
      ..write(obj.strictAmountCheck)
      ..writeByte(11)
      ..write(obj.autoApprove)
      ..writeByte(12)
      ..write(obj.senderIds)
      ..writeByte(13)
      ..write(obj.initialScanDays)
      ..writeByte(14)
      ..write(obj.allowForceApprove);
  }
}
