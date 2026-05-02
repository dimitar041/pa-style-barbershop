import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/work_schedule.dart';
import 'models.dart';
import 'slot_keys.dart';

class SlotUnavailableException implements Exception {
  SlotUnavailableException(this.message);
  final String message;
}

class CancellationTooLateException implements Exception {
  CancellationTooLateException(this.message);
  final String message;
}

class AppRepository {
  AppRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get currentUid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('profiles');

  CollectionReference<Map<String, dynamic>> get _services =>
      _firestore.collection('services');

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _barberProducts =>
      _firestore.collection('barberProducts');

  CollectionReference<Map<String, dynamic>> _blockedSlots(String barberProductId) =>
      _barberProducts.doc(barberProductId).collection('blockedSlots');

  Future<List<ServiceModel>> getServicesOnce() async {
    final snap = await _services.orderBy('price').get();
    return snap.docs
        .map((d) => ServiceModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Stream<List<ServiceModel>> watchServices() {
    return _services.orderBy('price').snapshots().map((snap) => snap.docs
        .map((d) => ServiceModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Future<List<BarberProductModel>> getBarberProductsOnce() async {
    final snap = await _barberProducts.orderBy('sortOrder').get();
    return snap.docs
        .map((d) => BarberProductModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Stream<List<BarberProductModel>> watchBarberProducts() {
    return _barberProducts.orderBy('sortOrder').snapshots().map((snap) => snap.docs
        .map((d) => BarberProductModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Future<Map<String, dynamic>> getProfileOnce(String uid) async {
    final doc = await _profiles.doc(uid).get();
    return doc.data() ?? {};
  }

  Stream<List<AppointmentModel>> watchClientAppointments(String clientId) {
    return _appointments
        .where('clientId', isEqualTo: clientId)
        .orderBy('startAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppointmentModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<List<AppointmentModel>> getClientAppointmentsOnce(
    String clientId, {
    int limit = 20,
  }) async {
    final snap = await _appointments
        .where('clientId', isEqualTo: clientId)
        .orderBy('startAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => AppointmentModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Future<List<AppointmentModel>> getBarberProductAppointmentsForDayOnce({
    required String barberProductId,
    required DateTime dayLocal,
  }) async {
    final slots = WorkSchedule.generateSlotsForLocalDate(dayLocal);
    if (slots.isEmpty) return const [];

    final dayStartUtc = slots.first.toUtc();
    final dayEndUtc =
        slots.last.add(const Duration(minutes: WorkSchedule.slotMinutes)).toUtc();

    final snap = await _appointments
        .where('barberProductId', isEqualTo: barberProductId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStartUtc))
        .where('startAt', isLessThan: Timestamp.fromDate(dayEndUtc))
        .orderBy('startAt')
        .limit(200)
        .get();
    return snap.docs
        .map((d) => AppointmentModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Future<List<BlockedSlotModel>> getBlockedSlotsForDayOnce({
    required String barberProductId,
    required DateTime dayLocal,
  }) async {
    final slots = WorkSchedule.generateSlotsForLocalDate(dayLocal);
    if (slots.isEmpty) return const [];

    final dayStartUtc = slots.first.toUtc();
    final dayEndUtc =
        slots.last.add(const Duration(minutes: WorkSchedule.slotMinutes)).toUtc();

    final snap = await _blockedSlots(barberProductId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStartUtc))
        .where('startAt', isLessThan: Timestamp.fromDate(dayEndUtc))
        .orderBy('startAt')
        .limit(200)
        .get();
    return snap.docs.map((d) {
      final doc = d as DocumentSnapshot<Map<String, dynamic>>;
      return BlockedSlotModel.fromDoc(doc.id, doc);
    }).toList();
  }

  Stream<List<AppointmentModel>> watchBarberProductAppointmentsForDay({
    required String barberProductId,
    required DateTime dayLocal,
  }) {
    final slots = WorkSchedule.generateSlotsForLocalDate(dayLocal);
    if (slots.isEmpty) return Stream.value(const []);

    final dayStartUtc = slots.first.toUtc();
    final dayEndUtc =
        slots.last.add(const Duration(minutes: WorkSchedule.slotMinutes)).toUtc();

    return _appointments
        .where('barberProductId', isEqualTo: barberProductId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStartUtc))
        .where('startAt', isLessThan: Timestamp.fromDate(dayEndUtc))
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                AppointmentModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Stream<List<BlockedSlotModel>> watchBlockedSlotsForDay({
    required String barberProductId,
    required DateTime dayLocal,
  }) {
    final slots = WorkSchedule.generateSlotsForLocalDate(dayLocal);
    if (slots.isEmpty) return Stream.value(const []);

    final dayStartUtc = slots.first.toUtc();
    final dayEndUtc =
        slots.last.add(const Duration(minutes: WorkSchedule.slotMinutes)).toUtc();

    return _blockedSlots(barberProductId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStartUtc))
        .where('startAt', isLessThan: Timestamp.fromDate(dayEndUtc))
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final doc = d as DocumentSnapshot<Map<String, dynamic>>;
              return BlockedSlotModel.fromDoc(doc.id, doc);
            }).toList());
  }

  String appointmentIdForBarberSlot({
    required String barberProductId,
    required DateTime slotStartUtc,
  }) {
    return '${barberProductId}_${slotKeyFromUtc(slotStartUtc)}';
  }

  Future<void> createAppointment({
    required String clientUid,
    required String barberProductId,
    required String serviceId,
    required DateTime slotStartLocal,
  }) async {
    final slotStartUtc = slotStartLocal.toUtc();
    final slotKey = slotKeyFromUtc(slotStartUtc);
    final appointmentId = appointmentIdForBarberSlot(
      barberProductId: barberProductId,
      slotStartUtc: slotStartUtc,
    );

    final blockedRef = _blockedSlots(barberProductId).doc(slotKey);
    final apRef = _appointments.doc(appointmentId);
    final endAtUtc = slotStartUtc.add(const Duration(minutes: WorkSchedule.slotMinutes));

    await _firestore.runTransaction((tx) async {
      final blockedSnap = await tx.get(blockedRef);
      if (blockedSnap.exists) {
        final reason = blockedSnap.data()?['reason']?.toString() ?? '';
        throw SlotUnavailableException('Слотът е блокиран. $reason');
      }

      final apSnap = await tx.get(apRef);
      if (apSnap.exists) {
        final status = apSnap.data()?['status'] as String? ?? '';
        if (status == 'confirmed') {
          throw SlotUnavailableException('Вече има запис за този час.');
        }
      }

      tx.set(apRef, {
        'clientId': clientUid,
        'barberProductId': barberProductId,
        'serviceId': serviceId,
        'startAt': timestampFromUtc(slotStartUtc),
        'endAt': timestampFromUtc(endAtUtc),
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'cancelReason': null,
        'cancelledAt': null,
      });
    });
  }

  Future<void> cancelAppointment({
    required String appointmentId,
    required String cancelledByUid,
    required String cancelReason,
  }) async {
    final apRef = _appointments.doc(appointmentId);
    final apSnap = await apRef.get();

    if (!apSnap.exists) throw Exception('Записът не съществува.');

    final data = apSnap.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'confirmed';
    if (status != 'confirmed') return;

    final clientId = data['clientId'] as String? ?? '';
    final startAt = (data['startAt'] as Timestamp).toDate().toUtc();

    if (cancelledByUid == clientId) {
      final cutoffUtc = startAt.subtract(const Duration(hours: 2));
      if (DateTime.now().toUtc().isAfter(cutoffUtc)) {
        throw CancellationTooLateException('Може да отмениш до 2 часа преди часа.');
      }
    }

    await apRef.update({
      'status': 'cancelled',
      'cancelReason': cancelReason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': cancelledByUid,
    });
  }

  Future<void> setBlockedSlot({
    required String barberProductId,
    required DateTime slotStartLocal,
    required String blockedByUid,
    required String reason,
    required bool blocked,
  }) async {
    final slotStartUtc = slotStartLocal.toUtc();
    final slotKey = slotKeyFromUtc(slotStartUtc);
    final blockedRef = _blockedSlots(barberProductId).doc(slotKey);

    if (!blocked) {
      await blockedRef.delete();
      return;
    }

    await blockedRef.set({
      'startAt': timestampFromUtc(slotStartUtc),
      'reason': reason,
      'blockedBy': blockedByUid,
      'blockedAt': FieldValue.serverTimestamp(),
    });

    final appointmentId = appointmentIdForBarberSlot(
      barberProductId: barberProductId,
      slotStartUtc: slotStartUtc,
    );
    final apRef = _appointments.doc(appointmentId);
    final apSnap = await apRef.get();
    if (!apSnap.exists) return;

    final data = apSnap.data() ?? {};
    if ((data['status'] as String? ?? '') != 'confirmed') return;

    final endAtUtc = slotStartUtc.add(const Duration(minutes: WorkSchedule.slotMinutes));
    await apRef.update({
      'status': 'cancelled',
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': blockedByUid,
      'endAt': timestampFromUtc(endAtUtc),
    });
  }

  Future<void> saveService({
    String? serviceId,
    required String nameBg,
    required double price,
    required int durationMinutes,
  }) async {
    final id = (serviceId == null || serviceId.trim().isEmpty)
        ? _services.doc().id
        : serviceId.trim();
    await _services.doc(id).set(
      {
        'nameBg': nameBg.trim(),
        'price': price,
        'durationMinutes': durationMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteService(String serviceId) async {
    await _services.doc(serviceId).delete();
  }

  Future<void> saveBarberProduct({
    String? productId,
    required String nameBg,
    required String imageUrl,
    required int sortOrder,
  }) async {
    final id = (productId == null || productId.trim().isEmpty)
        ? _barberProducts.doc().id
        : productId.trim();
    await _barberProducts.doc(id).set(
      {
        'nameBg': nameBg.trim(),
        'imageUrl': imageUrl.trim(),
        'sortOrder': sortOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteBarberProduct(String productId) async {
    await _barberProducts.doc(productId).delete();
  }

  Future<Map<String, dynamic>> fetchProfiles(Iterable<String> uids) async {
    final result = <String, dynamic>{};
    final list = uids.toList();
    const chunkSize = 10;

    for (var i = 0; i < list.length; i += chunkSize) {
      final chunk = list.sublist(i, (i + chunkSize).clamp(0, list.length));
      final snaps = await Future.wait(chunk.map((uid) => _profiles.doc(uid).get()));
      for (final doc in snaps) {
        result[doc.id] = doc.data() ?? {};
      }
    }

    return result;
  }
}
