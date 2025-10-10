import 'package:cloud_firestore/cloud_firestore.dart';

class SuKien {
  final String id;
  final String tieuDe;
  final DateTime thoiDiem;
  final DateTime? nhacLuc;
  final int mau;
  final String? ghiChu;
  final String nguoiTao;

  SuKien({
    required this.id,
    required this.tieuDe,
    required this.thoiDiem,
    this.nhacLuc,
    this.mau = 0xFF4CAF50,
    this.ghiChu,
    required this.nguoiTao,
  });

  Map<String, dynamic> toMap() => {
        'tieuDe': tieuDe,
        'thoiDiem': Timestamp.fromDate(thoiDiem),
        'nhacLuc': nhacLuc == null ? null : Timestamp.fromDate(nhacLuc!),
        'mau': mau,
        'ghiChu': ghiChu,
        'nguoiTao': nguoiTao,
      };

  static SuKien fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SuKien(
      id: doc.id,
      tieuDe: d['tieuDe'] ?? '',
      thoiDiem: (d['thoiDiem'] as Timestamp).toDate(),
      nhacLuc: d['nhacLuc'] == null ? null : (d['nhacLuc'] as Timestamp).toDate(),
      mau: (d['mau'] ?? 0xFF4CAF50) as int,
      ghiChu: d['ghiChu'],
      nguoiTao: d['nguoiTao'] ?? '',
    );
  }
}
