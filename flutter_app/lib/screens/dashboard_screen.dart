import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../providers/exam_provider.dart';
import '../models/exam.dart';
import 'create_exam.dart';
import '../providers/user_provider.dart';
import '../models/user_profile.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'scan_select_screen.dart';
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
      final userProvider = context.read<UserProvider>();
      final examProvider = context.read<ExamProvider>();
      
      final user = userProvider.user;
      if (user != null && user.id != null) {
        examProvider.initialize(user.id!, user.role);
        userProvider.initializeStats(user.id!, user.role);
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
            _buildDashboardHome(userProvider, user),
            const ScanSelectScreen(),
            const ResultsScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[100]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.grid_view_rounded, size: 24),
              ),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.qr_code_scanner_rounded, size: 24),
              ),
              label: 'Tara',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.bar_chart_rounded, size: 24),
              ),
              label: 'Sonuçlar',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.settings_rounded, size: 24),
              ),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome(UserProvider userProvider, UserProfile user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          const SizedBox(height: 24),
          _buildStatsCard(userProvider),
          const SizedBox(height: 32),
          _buildSectionHeader('YENİ SINAV OLUŞTUR'),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildExamTypeButton('LGS', true),
              const SizedBox(width: 12),
              _buildExamTypeButton('TYT', false),
              const SizedBox(width: 12),
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
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                label: const Text('ADMIN PANELI (KURUM EKLE)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2),
                  backgroundColor: const Color(0xFFF5F3FF), // purple-50
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMain),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _currentIndex = 2);
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F3FF),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Tümünü Gör', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentExamsList(),
        ],
      ),
    );
  }

  Widget _buildHeader(UserProfile user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_rounded, color: Color(0xFF475569), size: 22),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEDE9FE), width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFF5F3FF),
                child: Text(
                  user.initials,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard(UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(Icons.analytics_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Toplam Tarama', 
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                NumberFormat.decimalPattern('tr_TR').format(userProvider.totalScans), 
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 16),
              if (userProvider.growthRate != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        userProvider.growthRate >= 0 ? Icons.trending_up : Icons.trending_down, 
                        color: Colors.white, 
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${userProvider.growthRate >= 0 ? '+' : ''}${userProvider.growthRate}%', 
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
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
          return const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ));
        }

        if (provider.exams.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
                  child: const Icon(Icons.assignment_rounded, size: 32, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 16),
                const Text('Henüz Sınav Bulunmuyor', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('İlk sınavınızı oluşturarak başlayın.', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        final recentExams = provider.exams.take(5).toList();
        return Column(
          children: recentExams.map((exam) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildExamCard(context, exam, provider),
          )).toList(),
        );
      },
    );
  }

  Widget _buildExamCard(BuildContext context, Exam exam, ExamProvider provider) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateExamScreen(editExam: exam),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Builder(
              builder: (context) {
                Color statusColor = AppColors.primary;
                Color bgColor = const Color(0xFFF5F3FF);
                
                if (exam.type == 'LGS') {
                  statusColor = AppColors.green;
                  bgColor = AppColors.green.withOpacity(0.1);
                } else if (exam.type == 'TYT') {
                  statusColor = AppColors.orange;
                  bgColor = AppColors.orange.withOpacity(0.1);
                }
                
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.analytics_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                );
              }
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.name, 
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textMain),
                    overflow: TextOverflow.ellipsis,
                  ),
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
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label, 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
