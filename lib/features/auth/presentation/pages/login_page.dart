import 'dart:async';
import 'package:bargam_app/features/home/presentation/pages/home_page.dart';
import 'package:bargam_app/features/main/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // کنترلرها
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // متغیرهای وضعیت صفحه
  bool _isOtpSent = false;
  bool _localLoading = false; // لودینگ داخلی برای کنترل دکمه‌ها
  Timer? _timer;
  int _start = 120; // زمان تایمر (۲ دقیقه)

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- لاجیک تایمر ---
  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer?.cancel();
    setState(() {
      _start = 120;
    });
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- لاجیک ارسال شماره موبایل ---
  Future<void> _handleSendOtp() async {
    final phoneNumber = _phoneController.text.trim();

    // اعتبارسنجی ساده
    if (phoneNumber.length < 10 || !phoneNumber.startsWith('09')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل نامعتبر است (باید با ۰۹ شروع شود)'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _localLoading = true);

    final authProvider = context.read<AuthProvider>();
    // استفاده از خروجی Boolean که در پرووایدر تعریف کردیم
    final success = await authProvider.sendOtp(phoneNumber);

    if (!mounted) return;

    setState(() => _localLoading = false);

    if (success) {
      // اگر موفق بود، وضعیت را تغییر بده و تایمر را شروع کن
      setState(() {
        _isOtpSent = true;
      });
      _startTimer();
    } else {
      // نمایش خطا
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'خطا در برقراری ارتباط'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- لاجیک تایید کد ---
  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 5) return;

    setState(() => _localLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(_phoneController.text, otp);

    if (!mounted) return;
    setState(() => _localLoading = false);

    if (success) {
      // انتقال به صفحه اصلی و حذف صفحه لاگین از پشته (Stack)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'کد وارد شده صحیح نیست'),
          backgroundColor: Colors.red,
        ),
      );
      _otpController.clear(); // پاک کردن کد اشتباه
    }
  }

  // --- بازگشت به مرحله قبل (تغییر شماره) ---
  void _changeNumber() {
    _timer?.cancel();
    _otpController.clear();
    setState(() {
      _isOtpSent = false;
      _start = 120;
      // _phoneController را پاک نمی‌کنیم تا کاربر بتواند شماره قبلی را ویرایش کند
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // لوگو یا آیکون برنامه
                const Icon(Icons.eco, size: 80, color: Color(0xFF4CAF50)),
                const SizedBox(height: 24),

                const Text(
                  'ورود به حساب کاربری',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  _isOtpSent
                      ? 'کد تایید به شماره ${_phoneController.text} ارسال شد'
                      : 'برای ورود یا ثبت‌نام، شماره موبایل خود را وارد کنید',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // استفاده از AnimatedSwitcher برای جابجایی نرم بین فرم‌ها
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _isOtpSent
                      ? _buildOtpForm()  // نمایش فرم کد تایید
                      : _buildPhoneForm(), // نمایش فرم شماره
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- فرم شماره موبایل ---
  Widget _buildPhoneForm() {
    return Column(
      // *مهم*: این Key باعث می‌شود فلاتر هنگام سوییچ کردن، این ویجت را کاملا از نو بسازد
      // و مشکل TextEditingController حل شود.
      key: const ValueKey('PhoneForm'),
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr, // شماره‌ها چپ‌چین باشند
          decoration: const InputDecoration(
            labelText: 'شماره موبایل',
            hintText: '09xxxxxxxxx',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_android),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _localLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _localLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('دریافت کد تایید', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // --- فرم کد تایید (OTP) ---
  Widget _buildOtpForm() {
    // تنظیمات ظاهری Pinput
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Column(
      // *مهم*: Key منحصر به فرد برای جلوگیری از تداخل کنترلرها
      key: const ValueKey('OtpForm'),
      children: [
        Directionality(
          textDirection: TextDirection.ltr, // کدها چپ‌چین
          child: Pinput(
            controller: _otpController,
            length: 5, // طول کد ۵ رقم (طبق تنظیمات بک‌اند)
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyDecorationWith(
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            onCompleted: (_) => _handleVerify(), // ارسال خودکار بعد از وارد کردن آخرین رقم
          ),
        ),
        const SizedBox(height: 24),

        // تایمر یا دکمه ارسال مجدد
        if (_start > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_timerText, style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        else
          TextButton.icon(
            onPressed: _localLoading ? null : _handleSendOtp, // استفاده مجدد از تابع ارسال
            icon: const Icon(Icons.refresh),
            label: const Text('ارسال مجدد کد'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF4CAF50)),
          ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _localLoading ? null : _handleVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _localLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('تایید و ورود', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 12),
        TextButton(
          onPressed: _localLoading ? null : _changeNumber,
          child: const Text('تغییر شماره موبایل', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      ],
    );
  }
}
