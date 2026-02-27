import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../providers/exam_provider.dart';
import '../models/exam.dart';
import 'create_exam.dart';
import '../providers/user_provider.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'scanner_screen.dart';
import 'admin_panel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) {
        context.read<ExamProvider>().loadExams(user.id, user.role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (userProvider.isLoading || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFF),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardHome(user),
            const ScannerScreen(),
            const ResultsScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded, size: 22),
            activeIcon: Icon(Icons.grid_view_rounded, size: 22),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded, size: 22),
            label: 'Tara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded, size: 22),
            label: 'Sonuçlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 22),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHome(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          const SizedBox(height: 32),
          _buildStatsCard(),
          const SizedBox(height: 32),
          _buildSectionHeader('YENİ SINAV OLUŞTUR'),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildExamTypeButton('LGS', true),
              const SizedBox(width: 8),
              _buildExamTypeButton('TYT', false),
              const SizedBox(width: 8),
              _buildExamTypeButton('AYT', false),
            ],
          ),
          const SizedBox(height: 32),
          if (user.role == 'admin') ...[
            _buildSectionHeader('SİSTEM YÖNETİMİ'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                  );
                },
                icon: const Icon(Icons.shield_person_rounded),
                label: const Text('Admin Paneli (Kurum Ekle)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2),
                  backgroundColor: AppColors.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son Sınavlar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _currentIndex = 2);
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Tümünü Gör', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentExamsList(),
        ],
      ),
    );
  }

  Widget _buildHeader(user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[400]),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                user.initials,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.analytics_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bu Hafta Toplam Tarama', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              const Text('1,248', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('+12%', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.grey[500]),
    );
  }

  Widget _buildExamTypeButton(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateExamScreen(
                editExam: Exam(
                  id: '',
                  name: '',
                  type: title,
                  date: DateTime.now(),
                  subjects: [],
                ),
              ),
            ),
          );
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!, width: 2),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentExamsList() {
    return Consumer<ExamProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.exams.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[100]!, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[200]),
                const SizedBox(height: 16),
                const Text('Henüz kaydedilmiş sınav yok.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          );
        }

        final recentExams = provider.exams.take(5).toList();
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentExams.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildExamCard(context, recentExams[index], provider),
        );
      },
    );
  }

  Widget _buildExamCard(BuildContext context, Exam exam, ExamProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[50]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.assignment_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildTag(Icons.calendar_today_rounded, DateFormat('dd MMM', 'tr_TR').format(exam.date)),
                    const SizedBox(width: 8),
                    _buildTag(Icons.group_rounded, '${exam.studentCount} Öğrenci'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
