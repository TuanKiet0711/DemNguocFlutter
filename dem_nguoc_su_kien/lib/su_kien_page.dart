import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'su_kien.dart';

class SuKienPage extends StatelessWidget {
  const SuKienPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sự kiện'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('su_kien').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có sự kiện nào'));
          }

          final docs = snapshot.data!.docs;
          final suKiens = docs.map((e) => SuKien.fromDoc(e)).toList();

          return ListView.builder(
            itemCount: suKiens.length,
            itemBuilder: (context, index) {
              final sk = suKiens[index];
              final thoiGianConLai =
                  sk.thoiDiem.difference(DateTime.now()).inDays;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Color(sk.mau),
                child: ListTile(
                  title: Text(sk.tieuDe,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                    '${sk.ghiChu}\nCòn $thoiGianConLai ngày nữa',
                    style: const TextStyle(color: Colors.white70),
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
