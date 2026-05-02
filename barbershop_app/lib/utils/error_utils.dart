import 'package:firebase_auth/firebase_auth.dart';

String formatFirebaseError(Object e) {
  if (e is FirebaseException) {
    final msg = (e.message ?? '').trim();
    return msg.isNotEmpty ? '(${e.code}) $msg' : e.code;
  }
  final raw = e.toString();
  if (raw.contains('permission-denied')) return '(permission-denied) Нямаш права за това действие.';
  if (raw.contains('unauthenticated')) return '(unauthenticated) Трябва да си логнат.';
  if (raw.contains('failed-precondition')) return '(failed-precondition) Липсва Firestore индекс или условие.';
  if (raw.contains('not-found')) return '(not-found) Документът не е намерен.';
  return raw;
}
