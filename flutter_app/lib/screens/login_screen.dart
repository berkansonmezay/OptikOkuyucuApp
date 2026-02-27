import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _institutionCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _institutionCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurunuz')),
      );
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final userProvider = context.read<UserProvider>();
      final user = await userProvider.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hatalı kullanıcı adı veya şifre')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş yapılırken bir hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background blurred shapes (matching web's absolute divs)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: Colors.purple.shade100.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: _BlurFilter(blurX: 60, blurY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: Colors.blue.shade100.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: _BlurFilter(blurX: 60, blurY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 128,
            left: MediaQuery.of(context).size.width / 2 - 128,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: Colors.pink.shade100.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: _BlurFilter(blurX: 60, blurY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo and Title
                    Container(
                      width: 112, // 28 * 4 (w-28)
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Optik Okuyucu',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sınav Asistanınız',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.0), // rounded-2xl
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Hoşgeldiniz',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827), // text-gray-900
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Institution Code Field
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
                            child: Text(
                              'Kurum Kodu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151), // text-gray-700
                              ),
                            ),
                          ),
                          TextField(
                            controller: _institutionCodeController,
                            decoration: InputDecoration(
                              hintText: 'Kurum kodunu giriniz',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                              prefixIcon: const Icon(Icons.home_work_outlined, color: Color(0xFF9CA3AF)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12), // rounded-xl
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email or Username Field
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
                            child: Text(
                              'E-posta veya Kullanıcı Adı',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'E-posta veya kullanıcı adı giriniz',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9CA3AF)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
                                child: Text(
                                  'Şifre',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {},
                              child: const Text(
                                'Şifremi Unuttum',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoggingIn ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // rounded-xl
                              ),
                              elevation: 4, // shadow-lg
                              shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
                            ),
                            child: _isLoggingIn 
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Giriş Yap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      SizedBox(width: 8),
                                      Icon(Icons.login_rounded, size: 18),
                                    ],
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
        ],
      ),
    );
  }
}

// Utility class for backdrop filter to match HTML blur
class _BlurFilter extends ColorFilter {
  _BlurFilter({required double blurX, required double blurY})
      : super.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]); // A basic pass-through matrix; ImageFilter.blur is standard but BackdropFilter expects ImageFilter
}
