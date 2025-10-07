import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';

import '../su_kien.dart';
import '../services/du_lieu_su_kien.dart';
import 'them_su_kien_screen.dart';
import '../widgets/countdown_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = DuLieuSuKien();
  String? _avatarPath;
  final _prefsKey = 'avatar_path';
  final _avatarImages = List.generate(8, (i) => 'assets/avatars/a${i + 1}.png');

  @override
  void initState() {
    super.initState();
    _loadAvatarChoice();
  }

  Future<void> _loadAvatarChoice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _avatarPath = prefs.getString(_prefsKey));
  }

  Future<void> _saveAvatarChoice(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, path);
    }
    if (mounted) setState(() => _avatarPath = path);
  }

  /// 📸 Chọn avatar & crop
  Future<void> _pickAvatarFromGallery() async {
    bool granted = false;

    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final sdk = info.version.sdkInt;
      if (sdk >= 33) {
        final status = await Permission.photos.request();
        if (status.isGranted) granted = true;
        if (status.isPermanentlyDenied) await openAppSettings();
      } else {
        final status = await Permission.storage.request();
        if (status.isGranted) granted = true;
        if (status.isPermanentlyDenied) await openAppSettings();
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) granted = true;
      if (status.isPermanentlyDenied) await openAppSettings();
    }

    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền truy cập ảnh để chọn avatar.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Cắt ảnh', aspectRatioLockEnabled: true),
      ],
    );

    if (cropped != null) {
      await _saveAvatarChoice('file:${cropped.path}');
    }
  }

  Future<void> _resetAvatar() async => _saveAvatarChoice(null);

  Future<void> _chonAvatarAssets(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn avatar có sẵn'),
        content: SizedBox(
          width: 320,
          height: 260,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _avatarImages.length,
            itemBuilder: (context, i) {
              final path = _avatarImages[i];
              final selected = _avatarPath == 'asset:$path';
              return GestureDetector(
                onTap: () {
                  _saveAvatarChoice('asset:$path');
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.teal : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(path, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  DateTime _mocDemNguoc(SuKien e) {
    if (!e.lapHangNam) return e.thoiDiem;
    final now = DateTime.now();
    var t = DateTime(now.year, e.thoiDiem.month, e.thoiDiem.day, e.thoiDiem.hour, e.thoiDiem.minute);
    if (t.isBefore(now)) {
      t = DateTime(now.year + 1, t.month, t.day, t.hour, t.minute);
    }
    return t;
  }

  Future<bool> _confirmDelete(BuildContext context, SuKien e) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa sự kiện?'),
            content: Text('Bạn có chắc muốn xóa “${e.tieuDe}”?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _avatarWidget(User user) {
    if ((user.photoURL ?? '').isNotEmpty) {
      return CircleAvatar(radius: 20, backgroundImage: NetworkImage(user.photoURL!));
    }
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      if (_avatarPath!.startsWith('file:')) {
        final f = File(_avatarPath!.substring(5));
        if (f.existsSync()) {
          return CircleAvatar(radius: 20, backgroundImage: FileImage(f));
        }
      } else if (_avatarPath!.startsWith('asset:')) {
        return CircleAvatar(radius: 20, backgroundImage: AssetImage(_avatarPath!.substring(6)));
      }
    }
    return const CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, color: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Danh sách sự kiện')),
        body: const Center(child: Text('Bạn chưa đăng nhập.')),
      );
    }

    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        // Làm nền AppBar đẹp hơn với gradient + bo đáy
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF009688), Color(0xFF20B2AA)], // teal đậm → teal nhạt
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        title: const Text(
          'Danh sách sự kiện',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal, // fallback màu
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) async {
                switch (v) {
                  case 'pick':
                    await _pickAvatarFromGallery();
                    break;
                  case 'assets':
                    await _chonAvatarAssets(context);
                    break;
                  case 'reset':
                    await _resetAvatar();
                    break;
                  case 'logout':
                    await FirebaseAuth.instance.signOut();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'pick',
                  child: Row(
                    children: [Icon(Icons.photo_library, color: Colors.teal), SizedBox(width: 10), Text('Chọn từ thư viện')],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'assets',
                  child: Row(
                    children: [Icon(Icons.brush, color: Colors.teal), SizedBox(width: 10), Text('Chọn avatar có sẵn')],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'reset',
                  child: Row(
                    children: [Icon(Icons.refresh, color: Colors.grey), SizedBox(width: 10), Text('Về mặc định')],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [Icon(Icons.logout, color: Colors.redAccent), SizedBox(width: 10), Text('Đăng xuất')],
                  ),
                ),
              ],
              child: _avatarWidget(user),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF009688),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemSuKienScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm sự kiện'),
      ),
      body: StreamBuilder<List<SuKien>>(
        stream: _svc.suKienCua(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }

          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có sự kiện nào.\nNhấn + để thêm mới.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final e = data[i];
              final color = Color(e.mau);
              final moc = _mocDemNguoc(e);
              final time = DateFormat('HH:mm dd/MM/yyyy').format(e.thoiDiem);

              return Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => _confirmDelete(context, e),
                onDismissed: (_) => _svc.xoa(e.id),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(.25), color.withOpacity(.08)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withOpacity(.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.event, color: color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.tieuDe,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: .2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🕒 $time',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.black87,
                              ),
                            ),
                            if (e.ghiChu?.isNotEmpty == true)
                              Text(
                                '📝 ${e.ghiChu}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Khối đếm ngược nổi bật
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Còn lại',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: color.darken(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Widget này tự cập nhật, nên để riêng
                            CountdownText(target: moc),
                          ],
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

/// Nhỏ mà có võ: mở rộng Color cho tiện chỉnh sắc độ
extension _ColorX on Color {
  Color darken([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final h = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return h.toColor();
  }
}
