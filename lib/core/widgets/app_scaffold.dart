import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
         onPressed: () => context.push('/transaction-add'),
         child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
         shape: const CircularNotchedRectangle(),
         notchMargin: 8,
         color: Theme.of(context).cardTheme.color,
         child: SizedBox(
            height: 74,
            child: Row(
               children: [
                  Expanded(
                     child: _buildNavItem(
                        context,
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home,
                        label: 'Trang chủ',
                        isSelected: currentIndex == 0,
                        onTap: () => context.go('/dashboard'),
                     ),
                  ),
                  Expanded(
                     child: _buildNavItem(
                        context,
                        icon: Icons.list_alt_outlined,
                        selectedIcon: Icons.list_alt,
                        label: 'Giao dịch',
                        isSelected: currentIndex == 1,
                        onTap: () => context.go('/transactions'),
                     ),
                  ),
                  const SizedBox(width: 56),
                  Expanded(
                     child: _buildNavItem(
                        context,
                        icon: Icons.pie_chart_outline,
                        selectedIcon: Icons.pie_chart,
                        label: 'Báo cáo',
                        isSelected: currentIndex == 2,
                        onTap: () => context.go('/reports'),
                     ),
                  ),
                  Expanded(
                     child: _buildNavItem(
                        context,
                        icon: Icons.person_outline,
                        selectedIcon: Icons.person,
                        label: 'Cài đặt',
                        isSelected: currentIndex == 4,
                        onTap: () => context.go('/settings'),
                     ),
                  ),
               ],
            ),
         ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required IconData selectedIcon, required String label, required bool isSelected, required void Function() onTap}) {
     return InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
           width: double.infinity,
           child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(isSelected ? selectedIcon : icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 26),
                 const SizedBox(height: 4),
                 Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                 ),
              ]
           )
        )
     );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/budgets')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }
}
