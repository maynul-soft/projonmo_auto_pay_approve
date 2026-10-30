import 'package:hive/hive.dart';
import '../../models/sms_record.dart';

class SmsRecordAdapter extends TypeAdapter<SmsRecord> {
  @override
  final int typeId = 0;

  @override
  SmsRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsRecord(
      id: fields[0] as String,
      provider: fields[1] as String,
      sender: fields[2] as String,
      rawBody: fields[3] as String,
      txnId: fields[4] as String,
      amount: fields[5] as double,
      customer: fields[6] as String,
      fee: fields[7] as double?,
      commission: fields[8] as double?,
      balance: fields[9] as double?,
      smsDateTime: DateTime.fromMillisecondsSinceEpoch(fields[10] as int),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(fields[11] as int),
      status: fields[12] as String? ?? 'unmatched',
      matchedPaymentId: fields[13] as String?,
      approvedAt: fields[14] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[14] as int)
          : null,
      failReason: fields[15] as String?,
      attempts: fields[16] as int? ?? 0,
      approvedBy: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SmsRecord obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.provider)
      ..writeByte(2)
      ..write(obj.sender)
      ..writeByte(3)
      ..write(obj.rawBody)
      ..writeByte(4)
      ..write(obj.txnId)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.customer)
      ..writeByte(7)
      ..write(obj.fee)
      ..writeByte(8)
      ..write(obj.commission)
      ..writeByte(9)
      ..write(obj.balance)
      ..writeByte(10)
      ..write(obj.smsDateTime.millisecondsSinceEpoch)
      ..writeByte(11)
      ..write(obj.receivedAt.millisecondsSinceEpoch)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.matchedPaymentId)
      ..writeByte(14)
      ..write(obj.approvedAt?.millisecondsSinceEpoch)
      ..writeByte(15)
      ..write(obj.failReason)
      ..writeByte(16)
      ..write(obj.attempts)
      ..writeByte(17)
      ..write(obj.approvedBy);
  }
}
