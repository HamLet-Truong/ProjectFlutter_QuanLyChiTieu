import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final authNotifier = ref.read(authControllerProvider.notifier);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isLogin) {
        await authNotifier.login(email, password);
        return;
      }

      await authNotifier.register(name, email, password);
      if (!mounted) return;

      setState(() {
        _isLogin = true;
      });
      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công, vui lòng đăng nhập')),
      );
    } catch (_) {
      // Error state is already handled by provider and rendered in UI.
    }
  }

  Widget _buildAuthForm(
    BuildContext context, {
    String? errorText,
    required bool isLoading,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              SvgPicture.asset('assets/illustrations/welcome.svg', height: 120),
              const SizedBox(height: 40),
              Text(
                _isLogin ? 'Đăng nhập' : 'Tạo tài khoản',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Đăng nhập để đồng bộ dữ liệu chi tiêu'
                    : 'Nhập thông tin để bắt đầu đồng bộ dữ liệu chi tiêu',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (errorText != null && errorText.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  errorText,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (!_isLogin) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng nhập email';
                  if (!val.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (val.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin
                      ? 'Chưa có tài khoản? Đăng ký'
                      : 'Đã có tài khoản? Đăng nhập',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final errorText = authState.hasError ? '${authState.error}' : null;

    if (authState.valueOrNull != null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      body: _buildAuthForm(
        context,
        errorText: errorText,
        isLoading: isLoading,
      ),
    );
  }
}
