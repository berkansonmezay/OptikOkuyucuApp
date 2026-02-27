import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/user_provider.dart';
import '../models/user_profile.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isAdding = false;
  List<UserProfile> _institutions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  Future<void> _loadInstitutions() async {
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();
    final list = await userProvider.fetchAllInstitutions();
    setState(() {
      _institutions = list;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addInstitution() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);
    final success = await context.read<UserProvider>().addInstitution(
          _usernameController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

    setState(() => _isAdding = false);

    if (success) {
      _usernameController.clear();
      _passwordController.clear();
      _nameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kurum başarıyla eklendi')),
      );
      _loadInstitutions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hata: Kullanıcı adı zaten mevcut olabilir')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kurum Yönetimi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddSection(),
            const SizedBox(height: 32),
            const Text(
              'KAYITLI KURUMLAR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.black26,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildInstitutionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yeni Kurum Ekle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Sisteme yeni bir kullanıcı girişi tanımlayın.',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            _buildInputLabel('KULLANICI ADI'),
            _buildLightField(_usernameController, 'Örn: testkurum'),
            const SizedBox(height: 16),
            _buildInputLabel('ŞİFRE'),
            _buildLightField(_passwordController, '••••••••', isPassword: true),
            const SizedBox(height: 16),
            _buildInputLabel('KURUM KODU / ADI'),
            _buildLightField(_nameController, 'Örn: KURUM01'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAdding ? null : _addInstitution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isAdding
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kullanıcı Tanımla', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLightField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
    );
  }

  Widget _buildInstitutionsList() {
    if (_institutions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          children: [
            Icon(Icons.person_search_rounded, size: 48, color: Colors.grey[200]),
            const SizedBox(height: 16),
            const Text('Henüz kayıtlı kurum yok.', style: TextStyle(color: Colors.black26, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _institutions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final inst = _institutions[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inst.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(inst.email, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sil?'),
                      content: const Text('Bu kurumu silmek istediğinize emin misiniz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await context.read<UserProvider>().deleteInstitution(inst.id!);
                    _loadInstitutions();
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            ],
          ),
        );
      },
    );
  }
}
