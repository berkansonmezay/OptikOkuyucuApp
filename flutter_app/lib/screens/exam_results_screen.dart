import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/exam.dart';
import 'student_report_screen.dart';

class ExamResultsScreen extends StatefulWidget {
  final Exam exam;

  const ExamResultsScreen({super.key, required this.exam});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int? _expandedIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _averageScore {
    if (widget.exam.students.isEmpty) return 0.0;
    double total = widget.exam.students.fold(0, (sum, item) => sum + item.score);
    return total / widget.exam.students.length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = widget.exam.students.where((student) {
      return student.name.toLowerCase().contains(_searchQuery) ||
          student.studentNo.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildStatsBar()),
          SliverToBoxAdapter(child: _buildSearchField()),
          _buildStudentList(filteredStudents),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 26),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary, size: 26),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 100),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.exam.name,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${DateFormat('dd MMM, yyyy', 'tr_TR').format(widget.exam.date)} • ${widget.exam.type}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildStatBadge(Icons.groups_rounded, '${widget.exam.students.length} Öğrenci', const Color(0xFFF5F3FF), AppColors.primary),
          const SizedBox(width: 10),
          _buildStatBadge(Icons.equalizer_rounded, 'Ort: ${_averageScore.toStringAsFixed(2)}', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'İsim veya numara ile ara...',
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStudentList(List<StudentResult> students) {
    if (students.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.document_scanner_outlined, size: 64, color: Colors.grey[200]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'Henüz optik form taranmamış.' : 'Öğrenci bulunamadı.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    students.sort((a, b) => b.score.compareTo(a.score));

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final student = students[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStudentCard(student, index),
            );
          },
          childCount: students.length,
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentResult student, int index) {
    final bool isExpanded = _expandedIndex == index;
    final bool isWarning = student.score < 50.0;
    final Color primaryColor = isWarning ? Colors.orange : AppColors.primary;
    final Color bgColor = isWarning ? const Color(0xFFFFF7ED) : Colors.white;
    final Color borderColor = isWarning ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded && !isWarning ? const Color(0xFFF5F3FF).withOpacity(0.3) : bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpanded && !isWarning ? AppColors.primary.withOpacity(0.2) : borderColor,
          width: isExpanded || isWarning ? 2 : 1,
        ),
        boxShadow: isExpanded ? AppColors.softShadow : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isWarning ? const Color(0xFFFFEDD5) : const Color(0xFFF5F3FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        student.initials,
                        style: TextStyle(
                          color: isWarning ? const Color(0xFFEA580C) : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name.isEmpty ? 'İsimsiz Öğrenci' : student.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        if (isWarning)
                          Row(
                            children: [
                              const Icon(Icons.warning_rounded, size: 14, color: Color(0xFFEA580C)),
                              const SizedBox(width: 4),
                              const Text(
                                'OKUMA HATASI',
                                style: TextStyle(
                                  color: Color(0xFFEA580C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Öğrenci No: ${student.studentNo} • Kitapçık ${student.booklet ?? "-"}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isWarning ? '---' : student.score.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: isWarning ? const Color(0xFF94A3B8) : AppColors.primary,
                        ),
                      ),
                      if (!isWarning && index < 3)
                        const Text(
                          'DERECE',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildExpandedDetails(student, isWarning),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(StudentResult student, bool isWarning) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OPTİK OKUYUCU VERİSİ',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.content_copy_rounded, size: 14),
                      label: const Text('Kopyala', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Öğrenci No: ${student.studentNo}\nAd Soyad: ${student.name}\nKitapçık: ${student.booklet ?? "-"}\nCevaplar: ${student.rawAnswers ?? "Bulunamadı"}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_square,
                  label: 'Veriyi Düzenle',
                  color: const Color(0xFF1E293B),
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.analytics_rounded,
                  label: 'Karne',
                  color: AppColors.primary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentReportScreen(
                          exam: widget.exam,
                          result: student,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
    bool isSecondary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? Colors.white : color.withOpacity(0.1),
        foregroundColor: isSecondary ? const Color(0xFF334155) : color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSecondary ? const BorderSide(color: Color(0xFFE2E8F0)) : BorderSide.none,
        ),
      ),
    );
  }
}
