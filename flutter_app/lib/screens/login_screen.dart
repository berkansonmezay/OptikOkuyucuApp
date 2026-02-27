import 'dart:ui';
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
          // Background blurred shapes (matching web's login.html)
          Positioned(
            top: -96, // -top-24 (24 * 4)
            right: -96,
            child: Container(
              width: 256, // w-64 (64 * 4)
              height: 256,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF), // purple-100
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 72, sigmaY: 72), // filter blur-3xl
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -96, // -bottom-24
            left: -96,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE), // blue-100
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
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
                color: const Color(0xFFFCE7F3), // pink-100
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
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
                    Hero(
                      tag: 'app_logo',
                      child: const _LoginLogo(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Optik Okuyucu',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 30, // text-3xl
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.75,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sınav Asistanınız',
                      style: TextStyle(
                        color: Color(0xFF6B7280), // text-gray-500
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
                        border: Border.all(color: const Color(0xFFF3F4F6)), // border-gray-100
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04), // shadow-sm with 0.04
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
                            decoration: _inputDecoration(
                              hint: 'Kurum kodunu giriniz',
                              icon: Icons.home_work_outlined,
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
                            decoration: _inputDecoration(
                              hint: 'E-posta veya kullanıcı adı giriniz',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
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
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                              elevation: 10, // shadow-lg
                              shadowColor: AppColors.primary.withOpacity(0.3), // shadow-purple-200
                            ),
                            child: _isLoggingIn 
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
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

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112, // w-28
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // shadow-lg
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white, width: 4), // ring-4 ring-white
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
