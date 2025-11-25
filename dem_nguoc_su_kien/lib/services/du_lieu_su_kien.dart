import 'package:cloud_firestore/cloud_firestore.dart';
import '../su_kien.dart';

class DuLieuSuKien {
  final _db = FirebaseFirestore.instance;

  // Lấy sự kiện theo uid từ collection gốc /su_kien
  Stream<List<SuKien>> suKienCua(String uid) {
    return _db
        .collection('su_kien')
        .where('nguoiTao', isEqualTo: uid)
        .orderBy('thoiDiem')
        .snapshots()
        .map((s) => s.docs.map(SuKien.fromDoc).toList());
  }

  // Thêm sự kiện vào /su_kien
  Future<void> them(SuKien e) async {
    await _db.collection('su_kien').add(e.toMap());
  }

  // Xóa sự kiện từ /su_kien
  Future<void> xoa(String id) async {
    await _db.collection('su_kien').doc(id).delete();
  }
}
