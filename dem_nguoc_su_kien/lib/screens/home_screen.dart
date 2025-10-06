import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../su_kien.dart';
import '../services/du_lieu_su_kien.dart';
import 'them_su_kien_screen.dart';
import '../widgets/countdown_text.dart'; // <-- thêm dòng này

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = DuLieuSuKien();

  DateTime _mocDemNguoc(SuKien e) {
    if (!e.lapHangNam) return e.thoiDiem;
    var t = DateTime(DateTime.now().year, e.thoiDiem.month, e.thoiDiem.day,
        e.thoiDiem.hour, e.thoiDiem.minute);
    if (t.isBefore(DateTime.now())) {
      t = DateTime(DateTime.now().year + 1, t.month, t.day, t.hour, t.minute);
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách sự kiện')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ThemSuKienScreen())),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<SuKien>>(
        stream: _svc.suKienCua(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Chưa có sự kiện. Nhấn + để thêm.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = data[i];
              final moc = _mocDemNguoc(e);

              return Dismissible(
                key: ValueKey(e.id),
                background: Container(color: Colors.redAccent),
                onDismissed: (_) => _svc.xoa(e.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(e.mau).withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Color(e.mau)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.tieuDe,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            if (e.ghiChu?.isNotEmpty == true)
                              Text(e.ghiChu!, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ✨ Chỉ widget này tự tick, không rebuild cả list
                      CountdownText(target: moc),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
