import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/data/settings_local_storage.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
   ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
   bool _isSaving = false;

  final List<Map<String, String>> _pages = [
     {'title': 'Ghi chép chi tiêu dễ dàng', 'desc': 'Theo dõi tiền vào tiền ra mỗi ngày, rõ ràng và nhanh chóng.', 'asset': 'assets/illustrations/welcome.svg'},
     {'title': 'Quản lý ngân sách thông minh', 'desc': 'Đặt ngân sách theo danh mục và nhận cảnh báo khi sắp vượt mức.', 'asset': 'assets/illustrations/empty_state.svg'},
     {'title': 'Báo cáo trực quan', 'desc': 'Biểu đồ đơn giản, dễ đọc, giúp bạn nắm rõ tình hình tài chính cá nhân.', 'asset': 'assets/illustrations/error_state.svg'}, 
  ];

   @override
   void dispose() {
      _controller.dispose();
      super.dispose();
   }

   Future<void> _finishOnboarding() async {
      if (_isSaving) return;
      setState(() => _isSaving = true);

      final state = GoRouterState.of(context);
      final isPreview = state.uri.queryParameters['preview'] == '1';
      final user = ref.read(authControllerProvider).valueOrNull;

      await SettingsLocalStorage.setOnboardingCompleted(
         true,
         userId: user?.id,
         email: user?.email,
      );

      if (!mounted) return;
      if (isPreview) {
         context.go('/settings');
         return;
      }

      context.go(user == null ? '/auth' : '/dashboard');
   }

  @override
  Widget build(BuildContext context) {
      final isPreview = GoRouterState.of(context).uri.queryParameters['preview'] == '1';

    return Scaffold(
       body: SafeArea(
          child: Column(
             children: [
                Align(
                   alignment: Alignment.topRight,
                            child: TextButton(
                               onPressed: _finishOnboarding,
                               child: Text(isPreview ? 'Đóng' : 'Bỏ qua'),
                            ),
                ),
                Expanded(
                   child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: _pages.length,
                      itemBuilder: (ctx, i) {
                         return Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                  SvgPicture.asset(_pages[i]['asset']!, height: 200),
                                  const SizedBox(height: 48),
                                  Text(_pages[i]['title']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  Text(_pages[i]['desc']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5)),
                               ]
                            )
                         );
                      }
                   )
                ),
                Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                   child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(
                            children: List.generate(_pages.length, (i) => AnimatedContainer(
                               duration: const Duration(milliseconds: 300),
                               margin: const EdgeInsets.only(right: 8),
                               height: 8,
                               width: _currentPage == i ? 24 : 8,
                               decoration: BoxDecoration(color: _currentPage == i ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(4)),
                            ))
                         ),
                         ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                               if(_currentPage == _pages.length - 1) {
                                  _finishOnboarding();
                               } else {
                                  _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                               }
                            },
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_currentPage == _pages.length - 1 ? 'Bắt đầu ngay' : 'Tiếp tục')
                         )
                      ]
                   )
                )
             ]
          )
       )
    );
  }
}
