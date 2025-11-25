// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../language_controller.dart';
import '../../i18n/app_localizations.dart';
import '../su_kien.dart';
import '../services/du_lieu_su_kien.dart';
import 'them_su_kien_screen.dart';
import 'sua_su_kien_screen.dart';
import '../widgets/countdown_text.dart';

// 👇 thêm 2 import cho tour
import '../tutorial/coach_mark.dart';
import '../services/user_meta_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = DuLieuSuKien();
  String? _avatarPath;
  final _picker = ImagePicker();
  final _avatarImages = List.generate(8, (i) => 'assets/avatars/a${i + 1}.png');

  // 👇 các key để highlight trong tour
  final GlobalKey _kLang = GlobalKey();
  final GlobalKey _kAvatar = GlobalKey();
  final GlobalKey _kFab = GlobalKey();
  final GlobalKey _kEdit = GlobalKey();
  final GlobalKey _kDelete = GlobalKey();

  bool _guideStarted = false;
  bool _guideEditDeleteStarted = false;

  String get _prefsKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return 'avatar_path_$uid';
  }

  @override
  void initState() {
    super.initState();
    _loadAvatarChoice();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final should = await UserMetaService().shouldRunGuide(uid);
      if (!mounted || !should || _guideStarted) return;
      await Future.delayed(const Duration(milliseconds: 250));
      _startGuide();
    });
  }

  Future<void> _loadAvatarChoice() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _avatarPath = prefs.getString(_prefsKey));
  }

  Future<void> _saveAvatarChoice(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, path);
    }
    if (mounted) setState(() => _avatarPath = path);
  }

  Future<void> _pickAndCrop(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
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
        IOSUiSettings(
          title: 'Cắt ảnh',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped != null) await _saveAvatarChoice('file:${cropped.path}');
  }

  // 👇 Tour hướng dẫn chính
  Future<void> _startGuide() async {
    if (!mounted || _guideStarted) return;
    _guideStarted = true;

    final steps = <CoachStep>[
      CoachStep(
        key: _kLang,
        title: 'Đổi ngôn ngữ',
        body: 'Bấm để chuyển nhanh giữa Tiếng Việt và English.',
        align: Alignment.bottomCenter,
      ),
      CoachStep(
        key: _kAvatar,
        title: 'Hồ sơ & đăng xuất',
        body: 'Chạm avatar để thay ảnh, chọn ảnh có sẵn, hoặc đăng xuất.',
        align: Alignment.bottomCenter,
      ),
      CoachStep(
        key: _kFab,
        title: 'Thêm sự kiện mới',
        body: 'Bấm để tạo sự kiện và bắt đầu đếm ngược.',
        align: Alignment.topCenter,
      ),
    ];

    final coach = CoachMark(context, steps);
    await coach.start();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserMetaService().markGuided(uid);
    }
  }

  // 👇 Tour hướng dẫn Sửa/Xóa
  Future<void> _startGuideEditDelete() async {
    if (!mounted || _guideEditDeleteStarted) return;
    _guideEditDeleteStarted = true;

    final steps = <CoachStep>[
      CoachStep(
        key: _kEdit,
        title: 'Sửa sự kiện',
        body: 'Bấm để chỉnh lại tiêu đề, thời điểm hoặc ghi chú sự kiện.',
        align: Alignment.bottomCenter,
      ),
      CoachStep(
        key: _kDelete,
        title: 'Xóa sự kiện',
        body: 'Nếu không cần nữa, bạn có thể xóa sự kiện tại đây.',
        align: Alignment.topCenter,
      ),
    ];

    final coach = CoachMark(context, steps);
    await coach.start();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserMetaService().markGuidedEditDelete(uid);
    }
  }

  Widget _avatarWidget(User user) {
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      if (_avatarPath!.startsWith('file:')) {
        final f = File(_avatarPath!.substring(5));
        if (f.existsSync()) return CircleAvatar(radius: 22, backgroundImage: FileImage(f));
      } else if (_avatarPath!.startsWith('asset:')) {
        return CircleAvatar(radius: 22, backgroundImage: AssetImage(_avatarPath!.substring(6)));
      }
    }
    if ((user.photoURL ?? '').isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(user.photoURL!));
    }
    return const CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, color: Colors.teal),
    );
  }

  Widget _avatarMenu(User user) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      offset: const Offset(0, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      onSelected: (v) async {
        if (!mounted) return;
        switch (v) {
          case 'camera':
            await _pickAndCrop(ImageSource.camera);
            break;
          case 'pick':
            await _pickAndCrop(ImageSource.gallery);
            break;
          case 'assets':
            await showDialog(
              context: context,
              builder: (_) => SimpleDialog(
                title: const Text('Chọn avatar có sẵn'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _avatarImages.map((path) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _saveAvatarChoice('asset:$path');
                          },
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage(path),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'logout':
            await FirebaseAuth.instance.signOut();
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Bạn chưa đăng nhập.')));
    }

    final uid = user.uid;
    final now = DateTime.now();

    return AnimatedBuilder(
      animation: LanguageController.I,
      builder: (_, __) {
        final loc = AppLoc.of(context);
        return Scaffold(
          backgroundColor: const Color(0xFFF3F7F7),
          appBar: AppBar(
            title: Text(
              loc.titleEventList,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF009688), Color(0xFF20B2AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              ),
            ),
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            actions: [
              KeyedSubtree(
                key: _kLang,
                child: IconButton(
                  tooltip: loc.language,
                  icon: const Icon(Icons.language, color: Colors.white),
                  onPressed: () => LanguageController.I.toggle(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: KeyedSubtree(
                  key: _kAvatar,
                  child: _avatarMenu(user),
                ),
              ),
            ],
          ),
          floatingActionButton: KeyedSubtree(
            key: _kFab,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00A693),
              icon: const Icon(Icons.add, color: Colors.white, size: 26),
              label: Text(
                loc.addEvent,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThemSuKienScreen()),
                );
              },
            ),
          ),
          body: StreamBuilder<List<SuKien>>(
            stream: _svc.suKienCua(uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return Center(child: Text("Lỗi: ${snap.error}"));
              final data = snap.data ?? [];

              // Tour Sửa/Xóa khi có dữ liệu đầu tiên
              if (data.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final should = await UserMetaService().shouldRunGuideEditDelete(uid);
                  if (should && !_guideEditDeleteStarted) {
                    await Future.delayed(const Duration(milliseconds: 300));
                    _startGuideEditDelete();
                  }
                });
              }

              if (data.isEmpty) {
                return Center(
                  child: Text(loc.noEvents, style: const TextStyle(fontSize: 16)),
                );
              }

              final sapToi = data.where((e) => e.thoiDiem.isAfter(now)).toList()
                ..sort((a, b) => a.thoiDiem.compareTo(b.thoiDiem));
              final daDenHen = data.where((e) => e.thoiDiem.isBefore(now)).toList()
                ..sort((a, b) => b.thoiDiem.compareTo(a.thoiDiem));
              final all = [...sapToi, ...daDenHen];

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
                itemCount: all.length,
                itemBuilder: (_, i) {
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
                          color: color.withValues(alpha: .15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withValues(alpha: .8),
                                      color.withValues(alpha: .4),
                                    ],
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
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 16, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Text(
                                          time,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: Colors.black54,
                                          ),
                                        ),
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
                                  fontSize: 13.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha: .25)),
                            ),
                            child: Center(
                              child: isPast
                                  ? Text(
                                      loc.arrived,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                        fontSize: 16,
                                      ),
                                    )
                                  : CountdownText(
                                      target: e.thoiDiem,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: color.darken(),
                                      ),
                                      doneText: loc.arrived,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              KeyedSubtree(
                                key: _kEdit,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SuaSuKienScreen(suKien: e),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit, color: Colors.teal),
                                  label: Text(
                                    loc.edit,
                                    style: const TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              KeyedSubtree(
                                key: _kDelete,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(loc.deleteEvent),
                                        content: Text(loc.deleteConfirm(e.tieuDe)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text(loc.cancel),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                            ),
                                            child: Text(loc.delete),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      // 🔥 chỉ truyền id vì xoa(String id)
                                      await _svc.xoa(e.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(loc.deletedToast)),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: Text(
                                    loc.delete,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }
}

extension _ColorX on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
