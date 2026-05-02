import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  ServiceModel({
    required this.id,
    required this.nameBg,
    required this.price,
    this.durationMinutes = 30,
  });

  final String id;
  final String nameBg;
  final double price;
  final int durationMinutes;

  factory ServiceModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ServiceModel(
      id: doc.id,
      nameBg: (data['nameBg'] ?? data['name'] ?? '').toString(),
      price: (data['price'] ?? 0).toDouble(),
      durationMinutes: (data['durationMinutes'] ?? 30) as int,
    );
  }
}

class BarberProductModel {
  BarberProductModel({
    required this.id,
    required this.nameBg,
    this.imageUrl = '',
    this.sortOrder = 0,
  });

  final String id;
  final String nameBg;
  final String imageUrl;
  final int sortOrder;

  factory BarberProductModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BarberProductModel(
      id: doc.id,
      nameBg: (data['nameBg'] ?? data['name'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      sortOrder: (data['sortOrder'] is int)
          ? data['sortOrder'] as int
          : int.tryParse('${data['sortOrder'] ?? 0}') ?? 0,
    );
  }
}

enum AppointmentStatus { confirmed, cancelled }

AppointmentStatus appointmentStatusFromString(String? s) {
  switch (s) {
    case 'confirmed':
      return AppointmentStatus.confirmed;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    default:
      return AppointmentStatus.confirmed;
  }
}

class AppointmentModel {
  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.barberProductId,
    required this.serviceId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.status,
    this.cancelReason,
    this.cancelledAtUtc,
  });

  final String id;
  final String clientId;
  final String barberProductId;
  final String serviceId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final AppointmentStatus status;
  final String? cancelReason;
  final DateTime? cancelledAtUtc;

  factory AppointmentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final startTs = data['startAt'] as Timestamp?;
    final endTs = data['endAt'] as Timestamp?;
    return AppointmentModel(
      id: doc.id,
      clientId: (data['clientId'] ?? '') as String,
      barberProductId:
          (data['barberProductId'] ?? data['barberId'] ?? '') as String,
      serviceId: (data['serviceId'] ?? '') as String,
      startAtUtc:
          (startTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc(),
      endAtUtc:
          (endTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc(),
      status: appointmentStatusFromString(data['status'] as String?),
      cancelReason: data['cancelReason'] as String?,
      cancelledAtUtc:
          (data['cancelledAt'] as Timestamp?)?.toDate().toUtc(),
    );
  }
}

class BlockedSlotModel {
  BlockedSlotModel({
    required this.slotKey,
    required this.startAtUtc,
    required this.reason,
  });

  final String slotKey;
  final DateTime startAtUtc;
  final String reason;

  factory BlockedSlotModel.fromDoc(
    String slotKey,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final startTs = data['startAt'] as Timestamp?;
    return BlockedSlotModel(
      slotKey: slotKey,
      startAtUtc:
          (startTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc(),
      reason: (data['reason'] ?? '').toString(),
    );
  }
}
