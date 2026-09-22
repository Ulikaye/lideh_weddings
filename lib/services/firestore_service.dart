import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contributor.dart';
import '../models/event_details.dart';

/// All Firestore reads/writes live here so screens never touch
/// `FirebaseFirestore.instance` directly.
///
/// Collections:
///   event/config          - single doc, the wedding details (was localStorage `wc_event`)
///   contributors/{id}     - one doc per contributor (was localStorage `wc_contributors`)
///   meta/counter          - { count: n } used to generate WC-0001, WC-0002, ... ids
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _eventDoc =>
      _db.collection('event').doc('config');

  CollectionReference<Map<String, dynamic>> get _contributors =>
      _db.collection('contributors');

  DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _db.collection('meta').doc('counter');

  // ---------------- event ----------------

  Stream<EventDetails> streamEvent() {
    return _eventDoc.snapshots().map((doc) => EventDetails.fromMap(doc.data()));
  }

  Future<EventDetails> getEvent() async {
    final doc = await _eventDoc.get();
    return EventDetails.fromMap(doc.data());
  }

  Future<void> saveEvent(EventDetails event) {
    return _eventDoc.set(event.toMap(), SetOptions(merge: true));
  }

  // ---------------- contributors ----------------

  Stream<List<Contributor>> streamContributors() {
    return _contributors.orderBy('date', descending: true).snapshots().map(
        (snap) => snap.docs.map((d) => Contributor.fromSnapshot(d)).toList());
  }

  Future<Contributor?> getContributor(String id) async {
    final doc = await _contributors.doc(id).get();
    if (!doc.exists) return null;
    return Contributor.fromSnapshot(doc);
  }

  /// Atomically bumps `meta/counter.count` and returns a fresh id like
  /// `WC-0001`, so two devices adding a guest at the same moment never
  /// collide - this is the bit plain localStorage could never do.
  Future<String> _nextId() {
    return _db.runTransaction<String>((tx) async {
      final snap = await tx.get(_counterDoc);
      final current = (snap.data()?['count'] ?? 0) as int;
      final next = current + 1;
      tx.set(_counterDoc, {'count': next}, SetOptions(merge: true));
      return 'WC-${next.toString().padLeft(4, '0')}';
    });
  }

  Future<Contributor> addContributor({
    required String fullName,
    required String cardType,
    required num amount,
    required String date,
    required String phone,
  }) async {
    final id = await _nextId();
    final contributor = Contributor(
      id: id,
      fullName: fullName,
      cardType: cardType,
      amount: amount,
      date: date,
      phone: phone,
    );
    await _contributors.doc(id).set(contributor.toMap());
    return contributor;
  }

  Future<void> deleteContributor(String id) {
    return _contributors.doc(id).delete();
  }

  /// Marks a contributor checked in. Returns false (and leaves things
  /// untouched) if they were already checked in, so the scan screen can
  /// show "already checked in" like the original gate scanner did.
  Future<bool> checkIn(String id) async {
    final ref = _contributors.doc(id);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      if (snap.data()?['checkedIn'] == true) return false;
      tx.update(ref, {
        'checkedIn': true,
        'checkedInTime': DateTime.now().toIso8601String(),
      });
      return true;
    });
  }
}
