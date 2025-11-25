import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../i18n/app_localizations.dart';
import '../../language_controller.dart';
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
  int _mau = 0xFF4CAF50;

  String _fmt(DateTime d) =>
      DateFormat('HH:mm dd/MM/yyyy', LanguageController.I.locale.languageCode)
          .format(d);

  Future<DateTime?> _pickDateTime(DateTime? init, AppLoc loc) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: init ?? now,
      helpText: loc.pickDate,
      cancelText: loc.cancel,
      confirmText: loc.done,
      locale: LanguageController.I.locale,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: LanguageController.I.locale,
          child: Theme(
            data: ThemeData(
              colorScheme: const ColorScheme.light(primary: Colors.teal),
            ),
            child: child!,
          ),
        );
      },
    );
    if (d == null) return null;

    if (!mounted) return null;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init ?? now),
      helpText: loc.pickTime,
      cancelText: loc.cancel,
      confirmText: loc.done,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: LanguageController.I.locale,
          child: Theme(
            data: ThemeData(
              colorScheme: const ColorScheme.light(primary: Colors.teal),
            ),
            child: child!,
          ),
        );
      },
    );
    if (t == null) return null;

    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _luu(AppLoc loc) async {
    if (!_frm.currentState!.validate()) return;

    if (_thoiDiem == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.pleasePickTime)));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 👇 CHỈ TẠO 1 OBJECT – KHÔNG LÃNG PHÍ BIẾN
    final e = SuKien(
      id: 'auto',
      tieuDe: _tieuDe.text.trim(),
      thoiDiem: _thoiDiem!,
      mau: _mau,
      ghiChu: _ghiChu.text.trim().isEmpty ? null : _ghiChu.text.trim(),
      nguoiTao: uid,
    );

    // 👇 SỬ DỤNG BIẾN e – KHÔNG CÒN BÁO unused_local_variable
    await _svc.them(e);


    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(loc.saveEvent)));
  }

  @override
  void dispose() {
    _tieuDe.dispose();
    _ghiChu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLoc.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text(loc.addEvent,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 3,
      ),
      body: Form(
        key: _frm,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(
              controller: _tieuDe,
              decoration: InputDecoration(
                labelText: loc.eventTitle,
                hintText: loc.eventHint,
                prefixIcon: const Icon(Icons.title, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? loc.eventTitle : null,
            ),
            const SizedBox(height: 14),

            _buildCardTile(
              title: loc.eventTime,
              subtitle: _thoiDiem == null ? loc.notChosen : _fmt(_thoiDiem!),
              icon: Icons.calendar_month,
              color: Colors.teal,
              onTap: () async {
                final r = await _pickDateTime(_thoiDiem, loc);
                if (r != null) setState(() => _thoiDiem = r);
              },
            ),

            const SizedBox(height: 10),

            Text(loc.pickColor,
                style: const TextStyle(fontWeight: FontWeight.w600)),
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
                          color: _mau == c ? Colors.black : Colors.transparent,
                          width: 2.5,
                        ),
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
                labelText: loc.note,
                prefixIcon: const Icon(Icons.notes, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _luu(loc),
                icon: const Icon(Icons.save),
                label: Text(
                  loc.saveEvent,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
          backgroundColor: color.withValues(alpha: .15),
          child: Icon(icon, color: color),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
