import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/settings_local_storage.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

   @override
   ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
   final _nameCtrl = TextEditingController();
   final _emailCtrl = TextEditingController();
   final _noteCtrl = TextEditingController();

   bool _notificationEnabled = true;
   String? _avatarPath;
   bool _isLoadingLocal = true;
   bool _isSavingProfile = false;
   bool _profileSeeded = false;
   bool _isLoggingOut = false;

   @override
   void initState() {
      super.initState();
      _loadLocalSettings();
   }

   @override
   void dispose() {
      _nameCtrl.dispose();
      _emailCtrl.dispose();
      _noteCtrl.dispose();
      super.dispose();
   }

   Future<void> _loadLocalSettings() async {
      final enabled = await SettingsLocalStorage.getNotificationsEnabled();
      final note = await SettingsLocalStorage.getProfileNote();
      final avatarPath = await SettingsLocalStorage.getProfileAvatarPath();

      if (!mounted) return;
      setState(() {
         _notificationEnabled = enabled;
         _noteCtrl.text = note;
         _avatarPath = avatarPath;
         _isLoadingLocal = false;
      });
   }

   void _seedProfileFields(String name, String email) {
      if (_profileSeeded) return;
      _nameCtrl.text = name;
      _emailCtrl.text = email;
      _profileSeeded = true;
   }

   Future<void> _toggleNotifications(bool value) async {
      setState(() => _notificationEnabled = value);
      await SettingsLocalStorage.setNotificationsEnabled(value);
   }

   Future<void> _pickAvatar() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
         source: ImageSource.gallery,
         imageQuality: 85,
         maxWidth: 1200,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
      final savedPath = p.join(appDir.path, 'profile_avatar$ext');

      final copied = await File(picked.path).copy(savedPath);
      await SettingsLocalStorage.setProfileAvatarPath(copied.path);

      if (!mounted) return;
      setState(() => _avatarPath = copied.path);
   }

   Future<void> _saveProfile() async {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user == null) return;

      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      if (name.isEmpty || email.isEmpty) return;

      setState(() => _isSavingProfile = true);
      await ref.read(authControllerProvider.notifier).updateProfile(
               name: name,
               email: email,
            );
      await SettingsLocalStorage.setProfileNote(_noteCtrl.text.trim());

      if (!mounted) return;
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Đã lưu thông tin hồ sơ')),
      );
   }

   Future<void> _openOnboardingGuide() async {
      if (!mounted) return;
      context.go('/onboarding?preview=1');
   }

   Future<void> _resetOnboardingGuide() async {
      final user = ref.read(authControllerProvider).valueOrNull;
      await SettingsLocalStorage.resetOnboarding(
         userId: user?.id,
         email: user?.email,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Đã đặt lại hướng dẫn mở đầu')),
      );
   }

   Future<void> _logout() async {
      if (_isLoggingOut) return;

      setState(() => _isLoggingOut = true);
      try {
         await ref.read(authControllerProvider.notifier).logout();
         if (!mounted) return;
         context.go('/auth');
      } finally {
         if (mounted) {
            setState(() => _isLoggingOut = false);
         }
      }
   }

  @override
   Widget build(BuildContext context) {
      final authState = ref.watch(authControllerProvider);

      final user = authState.valueOrNull;
      if (user != null) {
         _seedProfileFields(user.name, user.email);
      }

      final hasAvatar = _avatarPath != null && File(_avatarPath!).existsSync();

    return Scaffold(
         appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
               Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                     color: Theme.of(context).cardTheme.color,
                     borderRadius: BorderRadius.circular(18),
                     border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                     ),
                  ),
                  child: Column(
                     children: [
                        Row(
                           children: [
                              Stack(
                                 children: [
                                    CircleAvatar(
                                       radius: 34,
                                       backgroundColor: AppColors.border,
                                       backgroundImage: hasAvatar ? FileImage(File(_avatarPath!)) : null,
                                       child: hasAvatar
                                             ? null
                                             : const Icon(Icons.person, size: 34, color: AppColors.textSecondary),
                                    ),
                                    Positioned(
                                       right: -2,
                                       bottom: -2,
                                       child: Material(
                                          color: AppColors.primary,
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                             customBorder: const CircleBorder(),
                                             onTap: _pickAvatar,
                                             child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                             ),
                                          ),
                                       ),
                                    ),
                                 ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                 child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                       Text(
                                          user?.name ?? 'Người dùng',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                       ),
                                       const SizedBox(height: 2),
                                       Text(
                                          user?.email ?? 'taikhoan@chitieu.app',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppColors.textSecondary),
                                       ),
                                       if (_noteCtrl.text.trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                             _noteCtrl.text.trim(),
                                             maxLines: 1,
                                             overflow: TextOverflow.ellipsis,
                                             style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                             ),
                                          ),
                                       ],
                                    ],
                                 ),
                              ),
                           ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                           controller: _nameCtrl,
                           decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                           ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                           controller: _emailCtrl,
                           keyboardType: TextInputType.emailAddress,
                           decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                           ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                           controller: _noteCtrl,
                           maxLines: 2,
                           decoration: const InputDecoration(
                              labelText: 'Ghi chú (tùy chọn)',
                              hintText: 'Ví dụ: mục tiêu tiết kiệm tháng này...',
                              prefixIcon: Icon(Icons.sticky_note_2_outlined),
                           ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                           width: double.infinity,
                           child: ElevatedButton.icon(
                              onPressed: _isSavingProfile ? null : _saveProfile,
                              icon: _isSavingProfile
                                    ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                       )
                                    : const Icon(Icons.save_outlined),
                              label: Text(_isSavingProfile ? 'Đang lưu...' : 'Lưu thay đổi'),
                           ),
                        ),
                     ],
                  ),
               ),
                  const SizedBox(height: 28),
               const Text('GIAO DIỆN & TRẢI NGHIỆM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
           const SizedBox(height: 12),
           Container(
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
              child: Column(
                 children: [
                    ListTile(
                      leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                      title: const Text('Giao diện'),
                      subtitle: const Text('Theo hệ thống', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onTap: (){},
                    ),
                    Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                      title: const Text('Thông báo'),
                                 trailing: Switch(
                                    value: _notificationEnabled,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: _isLoadingLocal ? null : _toggleNotifications,
                                 ),
                    ),
                    Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 1),
                    const ListTile(
                      leading: Icon(Icons.currency_exchange_rounded, color: AppColors.primary),
                      title: Text('Tiền tệ'),
                      subtitle: Text('Việt Nam Đồng (₫)', style: TextStyle(fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ),
                              Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 1),
                              const ListTile(
                                 leading: Icon(Icons.language_rounded, color: AppColors.primary),
                                 title: Text('Ngôn ngữ'),
                                 subtitle: Text('Tiếng Việt', style: TextStyle(fontSize: 12)),
                                 trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              ),
                 ]
              )
           ),
           const SizedBox(height: 32),
                const Text('DỮ LIỆU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
           const SizedBox(height: 12),
           Container(
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
              child: Column(
                 children: [
                    ListTile(
                       leading: const Icon(Icons.slideshow_outlined, color: AppColors.primary),
                       title: const Text('Xem lại hướng dẫn'),
                       subtitle: const Text('Mở lại phần giới thiệu ứng dụng', style: TextStyle(fontSize: 12)),
                       trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                       onTap: _openOnboardingGuide,
                    ),
                    Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 1),
                    ListTile(
                       leading: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                       title: const Text('Đặt lại hướng dẫn mở đầu'),
                       subtitle: const Text('Hiển thị lại onboarding cho tài khoản này', style: TextStyle(fontSize: 12)),
                       trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                       onTap: _resetOnboardingGuide,
                    ),
                    Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 1),
                    ListTile(
                       leading: const Icon(Icons.delete_outline, color: AppColors.expense),
                       title: const Text('Đặt lại dữ liệu', style: TextStyle(color: AppColors.expense)),
                       subtitle: const Text('Cảnh báo: thao tác này sẽ xóa toàn bộ dữ liệu', style: TextStyle(fontSize: 12)),
                       trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                       onTap: () {
                          showDialog(context: context, builder: (_) => AlertDialog(
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                             title: const Text('Xác nhận xóa dữ liệu?'),
                             content: const Text('Ứng dụng sẽ xóa toàn bộ dữ liệu đã lưu. Hành động này không thể hoàn tác.'),
                             actions: [
                                 TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary))),
                                 TextButton(onPressed: () async {
                                      await DatabaseHelper.instance.resetDB();
                                      await SettingsLocalStorage.clearAll();
                                      if(context.mounted) {
                                         Navigator.pop(context);
                                         context.go('/splash');
                                      }
                                 }, child: const Text('XÓA TOÀN BỘ', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold))),
                             ]
                          ));
                       },
                    ),
                 ],
              ),
           ),
           const SizedBox(height: 32),
           SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                 onPressed: _isLoggingOut
                     ? null
                     : () {
                          showDialog(
                             context: context,
                             builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Đăng xuất'),
                                content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản hiện tại?'),
                                actions: [
                                   TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Hủy'),
                                   ),
                                   TextButton(
                                      onPressed: () {
                                         Navigator.pop(context);
                                         _logout();
                                      },
                                      child: const Text(
                                         'Đăng xuất',
                                         style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700),
                                      ),
                                   ),
                                ],
                             ),
                          );
                       },
                 icon: _isLoggingOut
                     ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                       )
                     : const Icon(Icons.logout_rounded),
                 label: Text(_isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất'),
                 style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: BorderSide(color: AppColors.expense.withValues(alpha: 0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                 ),
              ),
           ),
           const SizedBox(height: 12),
           const Text('GIỚI THIỆU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
           const SizedBox(height: 12),
           Container(
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
              child: const Column(
                 children: [
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      title: Text('Giới thiệu ứng dụng'),
                      subtitle: Text('Sổ Chi Tiêu cá nhân phong cách Việt', style: TextStyle(fontSize: 12)),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.new_releases_outlined, color: AppColors.primary),
                      title: Text('Phiên bản ứng dụng'),
                      subtitle: Text('1.0.0', style: TextStyle(fontSize: 12)),
                    ),
                 ],
              ),
           ),
           const SizedBox(height: 48),
           const Center(child: Text('Phiên bản 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        ]
      )
    );
  }
}
