import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../cashier/home/cashier_home_page.dart';
import '../admin/dashboard/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _pwCtrl   = TextEditingController();
  bool _showPw    = false;
  bool _loading   = false;
  bool _rememberMe = false;
  String? _error;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('remember_me') ?? false;
    if (saved) {
      setState(() {
        _rememberMe = true;
        _userCtrl.text = prefs.getString('saved_username') ?? '';
        _pwCtrl.text   = prefs.getString('saved_password') ?? '';
      });
    }
  }

  Future<void> _saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', true);
    await prefs.setString('saved_username', username);
    await prefs.setString('saved_password', password);
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _pwCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_userCtrl.text.trim().isEmpty || _pwCtrl.text.isEmpty) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    setState(() { _loading = true; _error = null; });
    final state = context.read<AppState>();
    try {
      final ok = await state.login(_userCtrl.text.trim(), _pwCtrl.text, '');
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        if (_rememberMe) {
          await _saveCredentials(_userCtrl.text.trim(), _pwCtrl.text);
        } else {
          await _clearCredentials();
        }
        final role = state.currentUser?.role ?? 'cashier';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role == 'admin' ? const AdminDashboardPage() : const CashierHomePage(),
          ),
        );
      } else {
        setState(() => _error = 'Invalid username or password');
        _shakeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _loading = false; _error = msg; });
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) {
            final dx = _shakeAnim.value * 8 * ((_shakeCtrl.lastElapsedDuration?.inMilliseconds ?? 0) % 2 == 0 ? 1 : -1);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 60, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('asset/images/logo.webp', width: 64, height: 64),
                const SizedBox(height: 26),
                const Text('Welcome back',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.8)),
                const SizedBox(height: 6),
                const Text('Sign in to continue to EasyPos',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                const SizedBox(height: 32),

                AppTextField(label: 'USERNAME', controller: _userCtrl, placeholder: 'your username', noCorrect: true),
                const SizedBox(height: 14),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PASSWORD',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.2)),
                        // GestureDetector(
                        //   onTap: () {},
                        //   child: const Text('Forgot?',
                        //       style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      label: '',
                      controller: _pwCtrl,
                      obscure: !_showPw,
                      trailing: GestureDetector(
                        onTap: () => setState(() => _showPw = !_showPw),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(_showPw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _rememberMe ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _rememberMe ? AppColors.accent : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Text('Remember me',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
                ],

                const SizedBox(height: 20),
                _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                    : AppButton(label: 'Sign in', onPressed: _submit, expand: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
