import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';
import '../su_kien.dart';
import '../services/du_lieu_su_kien.dart';

class ThemSuKienScreen extends StatefulWidget {
  const ThemSuKienScreen({super.key});
  @override
  State<ThemSuKienScreen> createState() => _ThemSuKienScreenState();
}

class _ThemSuKienScreenState extends State<ThemSuKienScreen> {
  final _frm = GlobalKey<FormState>();
  final _svc = DuLieuSuKien();
  final _tieuDe = TextEditingController();
  final _ghiChu = TextEditingController();

  DateTime? _thoiDiem;
  DateTime? _nhacLuc;
  bool _lapHangNam = false;
  int _mau = 0xFF4CAF50;

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
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: Colors.teal),
          ),
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
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: Colors.teal),
          ),
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

  Future<void> _luu() async {
    if (!_frm.currentState!.validate()) return;
    if (_thoiDiem == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chọn thời điểm')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final e = SuKien(
      id: 'auto',
      tieuDe: _tieuDe.text.trim(),
      thoiDiem: _thoiDiem!,
      nhacLuc: _nhacLuc,
      lapHangNam: _lapHangNam,
      mau: _mau,
      ghiChu: _ghiChu.text.trim().isEmpty ? null : _ghiChu.text.trim(),
      nguoiTao: uid,
    );

    await _svc.them(e);

    if (_nhacLuc != null && _nhacLuc!.isAfter(DateTime.now())) {
      await _scheduleLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Sắp đến: ${e.tieuDe}',
        body: e.ghiChu,
        at: _nhacLuc!,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Đã lưu sự kiện')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('Thêm sự kiện'),
        centerTitle: true,
      ),
      body: Form(
        key: _frm,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // 🔹 Tiêu đề
            TextFormField(
              controller: _tieuDe,
              decoration: InputDecoration(
                labelText: 'Tiêu đề sự kiện',
                hintText: 'VD: Sinh nhật mẹ',
                prefixIcon: const Icon(Icons.title, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
            ),
            const SizedBox(height: 14),

            // 🔹 Thời điểm
            _buildCardTile(
              title: 'Thời điểm sự kiện',
              subtitle:
                  _thoiDiem == null ? 'Chưa chọn' : _fmt(_thoiDiem!),
              icon: Icons.calendar_month,
              color: Colors.teal,
              onTap: () async {
                final r = await _pickDateTime(_thoiDiem);
                if (r != null) setState(() => _thoiDiem = r);
              },
            ),
            const SizedBox(height: 8),

            // 🔹 Nhắc lúc
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

            // 🔹 Lặp hằng năm
            SwitchListTile(
              title: const Text('Lặp hằng năm'),
              value: _lapHangNam,
              onChanged: (v) => setState(() => _lapHangNam = v),
              activeColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: Colors.white,
            ),
            const SizedBox(height: 10),

            // 🔹 Màu
            const Text(
              'Chọn màu thẻ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              children: [
                for (final c in [
                  0xFF4CAF50,
                  0xFFF44336,
                  0xFF2196F3,
                  0xFFFFC107,
                  0xFF9C27B0
                ])
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
                          color:
                              _mau == c ? Colors.black : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          if (_mau == c)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // 🔹 Ghi chú
            TextField(
              controller: _ghiChu,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                prefixIcon: const Icon(Icons.notes, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔹 Nút lưu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _luu,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Lưu sự kiện',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey),
        ),
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
