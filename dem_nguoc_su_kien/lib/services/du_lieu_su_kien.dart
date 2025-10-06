import 'package:cloud_firestore/cloud_firestore.dart';
import '../su_kien.dart';

class DuLieuSuKien {
  final _db = FirebaseFirestore.instance;

  Stream<List<SuKien>> suKienCua(String uid) {
    return _db
        .collection('su_kien')
        .where('nguoiTao', isEqualTo: uid)
        .orderBy('thoiDiem')
        .snapshots()
        .map((s) => s.docs.map(SuKien.fromDoc).toList());
  }

  Future<void> them(SuKien e) => _db.collection('su_kien').add(e.toMap());

  Future<void> xoa(String id) => _db.collection('su_kien').doc(id).delete();
}
