import 'package:cloud_firestore/cloud_firestore.dart';

String slotKeyFromUtc(DateTime utcSlotStart) {
  final ms = utcSlotStart.toUtc().millisecondsSinceEpoch;
  return ms.toString();
}

Timestamp timestampFromUtc(DateTime utc) => Timestamp.fromDate(utc.toUtc());

