import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'su_kien.dart';

class SuKienPage extends StatelessWidget {
  const SuKienPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sự kiện'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
    .collection('su_kien')
    .where('nguoiTao', isEqualTo: uid)
    .orderBy('thoiDiem')
    .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có sự kiện nào'));
          }

          final docs = snapshot.data!.docs;
          final suKiens = docs.map((e) => SuKien.fromDoc(e)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: suKiens.length,
            itemBuilder: (context, index) {
              final sk = suKiens[index];
              final daysLeft =
                  sk.thoiDiem.difference(DateTime.now()).inDays;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: Color(sk.mau),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sk.tieuDe,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (sk.ghiChu != null)
                        Text(
                          sk.ghiChu!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        daysLeft >= 0
                            ? "⏳ Còn $daysLeft ngày nữa"
                            : "✔ Sự kiện đã diễn ra",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
