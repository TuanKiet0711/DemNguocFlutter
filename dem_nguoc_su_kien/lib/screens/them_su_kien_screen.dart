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
    );
    if (d == null) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init ?? now),
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
          'su_kien', // channel id
          'Sự kiện', // channel name
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm sự kiện')),
      body: Form(
        key: _frm,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tieuDe,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'VD: Sinh nhật mẹ',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Thời điểm sự kiện'),
              subtitle: Text(
                _thoiDiem == null ? 'Chưa chọn' : _fmt(_thoiDiem!),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final r = await _pickDateTime(_thoiDiem);
                if (r != null) setState(() => _thoiDiem = r);
              },
            ),
            ListTile(
              title: const Text('Nhắc lúc (tuỳ chọn)'),
              subtitle: Text(
                _nhacLuc == null ? 'Không nhắc' : _fmt(_nhacLuc!),
              ),
              trailing: const Icon(Icons.alarm),
              onTap: () async {
                final r = await _pickDateTime(_nhacLuc ?? _thoiDiem);
                if (r != null) setState(() => _nhacLuc = r);
              },
              onLongPress: () => setState(() => _nhacLuc = null),
            ),
            SwitchListTile(
              title: const Text('Lặp hằng năm'),
              value: _lapHangNam,
              onChanged: (v) => setState(() => _lapHangNam = v),
            ),
            const SizedBox(height: 8),
            const Text('Màu thẻ'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final c
                    in [0xFF4CAF50, 0xFFF44336, 0xFF2196F3, 0xFFFFC107, 0xFF9C27B0])
                  GestureDetector(
                    onTap: () => setState(() => _mau = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _mau == c ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ghiChu,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _luu,
              icon: const Icon(Icons.save),
              label: const Text('Lưu sự kiện'),
            ),
          ],
        ),
      ),
    );
  }
}
