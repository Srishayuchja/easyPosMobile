import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/login_page.dart';
import 'features/cashier/scan/scan_page.dart';
import 'features/admin/dashboard/admin_dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const EasyPosApp());
}

class EasyPosApp extends StatelessWidget {
  const EasyPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Easy POS Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _SplashGate(),
      ),
    );
  }
}

// Routes to the correct screen based on auth + loading state.
class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) return const _SplashScreen();
    if (state.currentUser != null) {
      return state.currentUser!.role == 'admin'
          ? const AdminDashboardPage()
          : const ScanPage();
    }
    return const LoginPage();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('asset/images/logo.webp', width: 80, height: 80),
            const SizedBox(height: 20),
            const Text('EasyPos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('Point of Sale', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
