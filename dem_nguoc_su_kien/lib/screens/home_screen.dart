// 🟢 HomeScreen.dart (đẹp hơn, giữ nguyên logic)
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
import 'sua_su_kien_screen.dart';
import '../widgets/countdown_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = DuLieuSuKien();
  String? _avatarPath;

  String get _prefsKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return 'avatar_path_$uid';
  }

  final _avatarImages = List.generate(8, (i) => 'assets/avatars/a${i + 1}.png');

  @override
  void initState() {
    super.initState();
    _loadAvatarChoice();
  }

  Future<void> _loadAvatarChoice() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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

  Future<void> _pickAvatarFromGallery() async {
    bool granted = false;
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final sdk = info.version.sdkInt;
      if (sdk >= 33) {
        final status = await Permission.photos.request();
        granted = status.isGranted;
      } else {
        final status = await Permission.storage.request();
        granted = status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      granted = status.isGranted || status.isLimited;
    }

    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cần quyền truy cập ảnh để chọn avatar.')));
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

    if (cropped != null) await _saveAvatarChoice('file:${cropped.path}');
  }

  Future<void> _pickAvatarFromCamera() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cần quyền Camera để chụp ảnh.')));
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
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

    if (cropped != null) await _saveAvatarChoice('file:${cropped.path}');
  }

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
                  child: ClipOval(child: Image.asset(path, fit: BoxFit.cover)),
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  Widget _avatarWidget(User user) {
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      if (_avatarPath!.startsWith('file:')) {
        final f = File(_avatarPath!.substring(5));
        if (f.existsSync()) return CircleAvatar(radius: 20, backgroundImage: FileImage(f));
      } else if (_avatarPath!.startsWith('asset:')) {
        return CircleAvatar(radius: 20, backgroundImage: AssetImage(_avatarPath!.substring(6)));
      }
    }
    if ((user.photoURL ?? '').isNotEmpty) {
      return CircleAvatar(radius: 20, backgroundImage: NetworkImage(user.photoURL!));
    }
    return const CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, color: Colors.teal),
    );
  }

  Widget _avatarMenu(User user) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 10),
      position: PopupMenuPosition.under,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      onSelected: (v) async {
        switch (v) {
          case 'camera':
            await _pickAvatarFromCamera();
            break;
          case 'pick':
            await _pickAvatarFromGallery();
            break;
          case 'assets':
            await _chonAvatarAssets(context);
            break;
          case 'logout':
            await FirebaseAuth.instance.signOut();
            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'camera', child: Text('📸 Chụp ảnh')),
        const PopupMenuItem(value: 'pick', child: Text('🖼️ Chọn từ thư viện')),
        const PopupMenuItem(value: 'assets', child: Text('✨ Chọn avatar có sẵn')),
        const PopupMenuItem(value: 'logout', child: Text('🚪 Đăng xuất')),
      ],
      child: _avatarWidget(user),
    );
  }

  // ========================== UI ==========================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Bạn chưa đăng nhập.')));
    }

    final uid = user.uid;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      appBar: AppBar(
        title: const Text('Danh sách sự kiện',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [Padding(padding: const EdgeInsets.only(right: 8), child: _avatarMenu(user))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemSuKienScreen()));
        },
        backgroundColor: Colors.teal,
        label: const Text("Thêm sự kiện", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<SuKien>>(
        stream: _svc.suKienCua(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text("Lỗi: ${snap.error}"));
          final data = snap.data ?? [];
          if (data.isEmpty) return const Center(child: Text("Chưa có sự kiện nào"));

          // 🔹 Sắp xếp gần đến hẹn lên đầu
          final sapToi = data.where((e) => e.thoiDiem.isAfter(now)).toList()
            ..sort((a, b) => a.thoiDiem.compareTo(b.thoiDiem));
          final daDenHen = data.where((e) => e.thoiDiem.isBefore(now)).toList()
            ..sort((a, b) => b.thoiDiem.compareTo(a.thoiDiem));
          final all = [...sapToi, ...daDenHen];

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
            itemCount: all.length,
            itemBuilder: (context, i) {
              final e = all[i];
              final color = Color(e.mau);
              final time = DateFormat('HH:mm dd/MM/yyyy').format(e.thoiDiem);
              final isPast = e.thoiDiem.isBefore(now);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Tiêu đề đẹp hơn ---
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withOpacity(.8), color.withOpacity(.4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.tieuDe,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 16, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text(time,
                                        style: const TextStyle(
                                            fontSize: 13.5, color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (e.ghiChu?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '📝 ${e.ghiChu}',
                            style: const TextStyle(
                                fontSize: 13.5, color: Colors.black54, height: 1.3),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(.25)),
                        ),
                        child: Center(
                          child: isPast
                              ? const Text('ĐÃ ĐẾN HẸN',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                      fontSize: 16))
                              : CountdownText(
                                  target: e.thoiDiem,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color.darken(),
                                  ),
                                  doneText: 'ĐÃ ĐẾN HẸN',
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SuaSuKienScreen(suKien: e)),
                              );
                            },
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            label: const Text('Sửa',
                                style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w600)),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Xoá sự kiện'),
                                  content:
                                      Text('Bạn có chắc muốn xoá "${e.tieuDe}" không?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Hủy')),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent),
                                      child: const Text('Xoá'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _svc.xoa(e.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('🗑️ Đã xoá sự kiện')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Xoá',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      )
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

extension _ColorX on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
