import 'package:cloud_firestore/cloud_firestore.dart';

class UserMetaService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Future<void> ensureNewUserDoc(
    String uid, {
    String? email,
    String? displayName,
    String? photoURL,
  }) async {
    final doc = _col.doc(uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'createdAt': FieldValue.serverTimestamp(),
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'onboarded': false,
        'guided': false,
        'guidedEditDelete': false,
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getMeta(String uid) {
    return _col.doc(uid).get();
  }

  Future<void> markOnboarded(String uid) async {
    await _col.doc(uid).set({'onboarded': true}, SetOptions(merge: true));
  }

  Future<bool> shouldRunGuide(String uid) async {
    final snap = await getMeta(uid);
    final data = snap.data() ?? {};
    return (data['guided'] != true);
  }

  Future<void> markGuided(String uid) async {
    await _col.doc(uid).set({'guided': true}, SetOptions(merge: true));
  }

  Future<bool> shouldRunGuideEditDelete(String uid) async {
    final snap = await getMeta(uid);
    final data = snap.data() ?? {};
    return (data['guidedEditDelete'] != true);
  }

  Future<void> markGuidedEditDelete(String uid) async {
    await _col.doc(uid).set({'guidedEditDelete': true}, SetOptions(merge: true));
  }
}
