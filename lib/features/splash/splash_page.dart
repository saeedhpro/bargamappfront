import 'package:bargam_app/features/auth/presentation/pages/login_page.dart';
import 'package:bargam_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bargam_app/features/main/main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // ۱. حداقل ۲ ثانیه صبر می‌کنیم تا انیمیشن دیده شود
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // ۲. اگر وضعیت هنوز Loading یا Initial بود، در یک حلقه صبر می‌کنیم
    // (این برای وقتی است که اینترنت کند است و درخواست به سرور هنوز تمام نشده)
    int retryCount = 0;
    while ((authProvider.status == AuthStatus.initial ||
        authProvider.status == AuthStatus.loading) &&
        retryCount < 50) { // حداکثر ۵ ثانیه اضافه صبر میکنه
      await Future.delayed(const Duration(milliseconds: 100));
      retryCount++;
    }

    if (!mounted) return;

    // ۳. تصمیم‌گیری نهایی
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      // چه ارور داده باشد، چه توکن نداشته باشد، میرود لاگین
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 80,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'برگام',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'دستیار هوشمند نگهداری گیاهان',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // نمایش لودینگ تا زمانی که وضعیت مشخص شود
                    Consumer<AuthProvider>(
                      builder: (context, provider, child) {
                        // اگر بیشتر از ۲ ثانیه طول کشید و هنوز داریم چک می‌کنیم، اسپینر نشان بده
                        if (_controller.isCompleted &&
                            (provider.status == AuthStatus.loading || provider.status == AuthStatus.initial)) {
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CAF50),
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 24); // جای خالی
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
