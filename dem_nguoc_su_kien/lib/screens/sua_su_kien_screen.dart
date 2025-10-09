import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../main.dart';
import '../su_kien.dart';
import '../services/du_lieu_su_kien.dart';

class SuaSuKienScreen extends StatefulWidget {
  final SuKien suKien;
  const SuaSuKienScreen({super.key, required this.suKien});

  @override
  State<SuaSuKienScreen> createState() => _SuaSuKienScreenState();
}

class _SuaSuKienScreenState extends State<SuaSuKienScreen> {
  final _frm = GlobalKey<FormState>();
  final _svc = DuLieuSuKien();

  late TextEditingController _tieuDe;
  late TextEditingController _ghiChu;

  DateTime? _thoiDiem;
  DateTime? _nhacLuc;
  bool _lapHangNam = false;
  int _mau = 0xFF4CAF50;

  @override
  void initState() {
    super.initState();
    final e = widget.suKien;
    _tieuDe = TextEditingController(text: e.tieuDe);
    _ghiChu = TextEditingController(text: e.ghiChu ?? '');
    _thoiDiem = e.thoiDiem;
    _nhacLuc = e.nhacLuc;
    _lapHangNam = e.lapHangNam;
    _mau = e.mau;
  }

  String _fmt(DateTime d) => DateFormat('HH:mm dd/MM/yyyy').format(d);

  Future<DateTime?> _pickDateTime(DateTime? init) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: init ?? now,
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Xong',
      builder: (context, child) {
        return Theme(
          data: ThemeData(colorScheme: const ColorScheme.light(primary: Colors.teal)),
          child: child!,
        );
      },
    );
    if (d == null) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init ?? now),
      helpText: 'Chọn giờ',
      cancelText: 'Hủy',
      confirmText: 'Xong',
      builder: (context, child) {
        return Theme(
          data: ThemeData(colorScheme: const ColorScheme.light(primary: Colors.teal)),
          child: child!,
        );
      },
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    String? body,
    required DateTime at,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'su_kien',
          'Sự kiện',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> _capNhat() async {
    if (!_frm.currentState!.validate()) return;
    if (_thoiDiem == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chọn thời điểm')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final data = {
      'tieuDe': _tieuDe.text.trim(),
      'thoiDiem': Timestamp.fromDate(_thoiDiem!),
      'nhacLuc': _nhacLuc == null ? null : Timestamp.fromDate(_nhacLuc!),
      'lapHangNam': _lapHangNam,
      'mau': _mau,
      'ghiChu': _ghiChu.text.trim().isEmpty ? null : _ghiChu.text.trim(),
      'nguoiTao': uid,
    };

    await FirebaseFirestore.instance.collection('su_kien').doc(widget.suKien.id).update(data);

    // Schedule lại thông báo nếu có nhắc lúc
    if (_nhacLuc != null && _nhacLuc!.isAfter(DateTime.now())) {
      final baseId = widget.suKien.id.hashCode & 0x7FFFFFFF;

      await _scheduleLocalNotification(
        id: baseId,
        title: 'Sắp đến: ${_tieuDe.text.trim()}',
        body: _ghiChu.text.trim().isEmpty ? null : _ghiChu.text.trim(),
        at: _nhacLuc!,
      );

      // Nếu lặp năm: đặt thêm năm sau
      if (_lapHangNam) {
        final nextYear = DateTime(
          _nhacLuc!.year + 1,
          _nhacLuc!.month,
          _nhacLuc!.day,
          _nhacLuc!.hour,
          _nhacLuc!.minute,
        );
        await _scheduleLocalNotification(
          id: baseId + 1,
          title: 'Sắp đến: ${_tieuDe.text.trim()} (năm sau)',
          body: _ghiChu.text.trim().isEmpty ? null : _ghiChu.text.trim(),
          at: nextYear,
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật sự kiện')));
  }

  @override
  void dispose() {
    _tieuDe.dispose();
    _ghiChu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Sửa sự kiện',style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  ),),
        
        centerTitle: true,
      ),
      body: Form(
        key: _frm,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(
              controller: _tieuDe,
              decoration: InputDecoration(
                labelText: 'Tiêu đề sự kiện',
                prefixIcon: const Icon(Icons.title, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
            ),
            const SizedBox(height: 14),

            _buildCardTile(
              title: 'Thời điểm sự kiện',
              subtitle: _thoiDiem == null ? 'Chưa chọn' : _fmt(_thoiDiem!),
              icon: Icons.calendar_month,
              color: Colors.teal,
              onTap: () async {
                final r = await _pickDateTime(_thoiDiem);
                if (r != null) setState(() => _thoiDiem = r);
              },
            ),
            const SizedBox(height: 8),

            _buildCardTile(
              title: 'Nhắc lúc (tùy chọn)',
              subtitle: _nhacLuc == null ? 'Không nhắc' : _fmt(_nhacLuc!),
              icon: Icons.alarm,
              color: Colors.orange,
              onTap: () async {
                final r = await _pickDateTime(_nhacLuc ?? _thoiDiem);
                if (r != null) setState(() => _nhacLuc = r);
              },
              onLongPress: () => setState(() => _nhacLuc = null),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Lặp hằng năm'),
              value: _lapHangNam,
              onChanged: (v) => setState(() => _lapHangNam = v),
              activeColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: Colors.white,
            ),
            const SizedBox(height: 10),

            const Text('Chọn màu thẻ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              children: [
                for (final c in [0xFF4CAF50, 0xFFF44336, 0xFF2196F3, 0xFFFFC107, 0xFF9C27B0])
                  GestureDetector(
                    onTap: () => setState(() => _mau = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _mau == c ? Colors.black : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          if (_mau == c)
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _ghiChu,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                prefixIcon: const Icon(Icons.notes, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _capNhat,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      elevation: 1.5,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
