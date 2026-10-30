import 'package:hive/hive.dart';
import '../../models/pending_payment.dart';

class PendingPaymentAdapter extends TypeAdapter<PendingPayment> {
  @override
  final int typeId = 1;

  @override
  PendingPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingPayment(
      paymentId: fields[0] as String,
      txnId: fields[1] as String,
      amount: fields[2] as double,
      customer: fields[3] as String?,
      method: fields[4] as String?,
      createdAt: fields[5] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[5] as int)
          : null,
      rawJson: fields[6] as String?,
      lastFetchedAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
    );
  }

  @override
  void write(BinaryWriter writer, PendingPayment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.paymentId)
      ..writeByte(1)
      ..write(obj.txnId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.customer)
      ..writeByte(4)
      ..write(obj.method)
      ..writeByte(5)
      ..write(obj.createdAt?.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.rawJson)
      ..writeByte(7)
      ..write(obj.lastFetchedAt.millisecondsSinceEpoch);
  }
}
