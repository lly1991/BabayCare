import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../baby/presentation/providers/baby_providers.dart';
import '../../../session/application/session_providers.dart';
import '../providers/auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _isLogin = true;
  bool _submitting = false;
  String? _errorText;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFF2F2F7)),
          const _Blob(
            size: 280,
            top: -80,
            right: -60,
            color: Color(0xFFFF9F9F),
          ),
          const _Blob(
            size: 200,
            bottom: 80,
            left: -60,
            color: Color(0xFF4ECDC4),
          ),
          const _Blob(
            size: 160,
            bottom: 200,
            right: 40,
            color: Color(0xFFFFE66D),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text('🍼', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 12),
                      const Text(
                        'BabyCare',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '记录宝宝成长每一刻',
                        style: TextStyle(
                          color: Color(0xFF6C6C70),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        child: Column(
                          children: [
                            _buildSwitch(),
                            const SizedBox(height: 18),
                            _buildField(
                              controller: _usernameController,
                              label: '用户名',
                              hint: '请输入用户名',
                              icon: Icons.person_outline,
                              obscureText: false,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _passwordController,
                              label: '密码',
                              hint: '请输入密码',
                              icon: Icons.lock_outline,
                              obscureText: true,
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 12),
                              _buildField(
                                controller: _confirmPasswordController,
                                label: '确认密码',
                                hint: '请再次输入密码',
                                icon: Icons.lock_outline,
                                obscureText: true,
                              ),
                            ],
                            if (_errorText != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Color(0xFFFF3B30),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF9F9F),
                                      Color(0xFFFF6B6B)
                                    ],
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x4DFF6B6B),
                                      blurRadius: 16,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: FilledButton(
                                  onPressed: _submitting ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: _submitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isLogin ? '登录' : '注册',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _SwitchButton(
              title: '登录',
              selected: _isLogin,
              onTap: () => _switchMode(isLogin: true),
            ),
          ),
          Expanded(
            child: _SwitchButton(
              title: '注册',
              selected: !_isLogin,
              onTap: () => _switchMode(isLogin: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscureText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF9F9F), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  void _switchMode({required bool isLogin}) {
    setState(() {
      _isLogin = isLogin;
      _errorText = null;
    });
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorText = '请输入用户名和密码');
      return;
    }

    if (!_isLogin && password != confirmPassword) {
      setState(() => _errorText = '两次输入的密码不一致');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final babyRepo = ref.read(babyRepositoryProvider);

      if (_isLogin) {
        final user = await authRepo.login(username, password);
        if (user == null || user.id == null) {
          setState(() => _errorText = '用户名或密码错误');
          return;
        }
        final babies = await babyRepo.getByUser(user.id!);
        ref.read(sessionControllerProvider.notifier).setAuthenticatedUser(
              user.id!,
              babyId: babies.isEmpty ? null : babies.first.id,
            );
      } else {
        final user = await authRepo.register(username, password);
        ref
            .read(sessionControllerProvider.notifier)
            .setAuthenticatedUser(user.id!);
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() => _errorText = message.isEmpty ? '操作失败，请重试' : message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected ? Colors.white : Colors.transparent,
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF1C1C1E) : const Color(0xFF6C6C70),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double size;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
