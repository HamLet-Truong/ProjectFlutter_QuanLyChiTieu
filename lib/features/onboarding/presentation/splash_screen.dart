import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 124,
                    height: 124,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Quản Lý Chi Tiêu', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Quản lý tiền bạc gọn gàng mỗi ngày', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
             ]
           )
        )
     );
  }
}
