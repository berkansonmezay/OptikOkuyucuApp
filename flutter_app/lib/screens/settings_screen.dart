import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/user_provider.dart';
import 'edit_profile_screen.dart';
import 'scoring_config_screen.dart';
import 'login_screen.dart';
import 'admin_panel_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textMain)),
        backgroundColor: const Color(0xFFFDFDFF),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(userProvider),
            const SizedBox(height: 32),

            _buildSectionHeader('KULLANICI BİLGİLERİ'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildSettingsItem(Icons.person_outline, 'Profili Düzenle', () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              )),
              _buildDivider(),
              _buildSettingsItem(Icons.lock_outline_rounded, 'Şifre ve Güvenlik', null),
            ]),

            if (isAdmin) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('SİSTEM YÖNETİMİ'),
              const SizedBox(height: 12),
              _buildSettingsGroup([
                _buildSettingsItem(Icons.person_add_alt_1_rounded, 'Yeni Kurum Ekle', () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                )),
                _buildDivider(),
                _buildSettingsItem(Icons.group_rounded, 'Kurum Listesi (Düzenle)', () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                )),
              ]),
            ],

            const SizedBox(height: 24),
            _buildSectionHeader('TEKNİK ÖZELLİKLER'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildDropdownItem(Icons.code_rounded, 'Kodlama (Encoding)', ['UTF-8', 'Windows-1254', 'ISO-8859-9'], 'UTF-8'),
              _buildDivider(),
              _buildDropdownItem(Icons.view_column_rounded, 'Alan Ayırıcı (Delimiter)', ['Virgül (,)', 'Noktalı Virgül (;)', 'Tab ( \\t )'], 'Virgül (,)'),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader('PUANLAMA YAPILANDIRMASI'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildSettingsItem(Icons.assignment_rounded, 'Sınavlar', () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScoringConfigScreen()),
              ), subtitle: 'Puan atama ve sınav bazlı ayarlar', iconSize: 28),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader('DİĞER'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildSettingsItem(Icons.help_outline_rounded, 'Yardım & Destek', null),
              _buildDivider(),
              _buildSettingsItem(Icons.info_outline_rounded, 'Uygulama Hakkında', null),
            ]),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await context.read<UserProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Color(0xFFFEF2F2), width: 1)
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'VERSİYON 1.0.0', 
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF8FAFC), indent: 24, endIndent: 24);
  }

  Widget _buildDropdownItem(IconData icon, String title, List<String> items, String selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF94A3B8)),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                onChanged: (String? newValue) {
                  // Currently UI only mock to match web
                },
                items: items.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserProvider userProvider) {
    final user = userProvider.user;
    if (user == null) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  user.role == 'admin' ? 'Sistem Yöneticisi' : user.institution,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF94A3B8), size: 20),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback? onTap, {String? subtitle, double iconSize = 20}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: iconSize),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 24),
          ],
        ),
      ),
    );
  }
}
