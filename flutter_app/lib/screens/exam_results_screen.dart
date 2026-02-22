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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter students based on search query
    final filteredStudents = widget.exam.students.where((student) {
      return student.studentName.toLowerCase().contains(_searchQuery) ||
          student.studentNumber.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              '${DateFormat('dd MMM, yyyy', 'tr_TR').format(widget.exam.date)} • ${widget.exam.type}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined, color: AppColors.primary)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, color: AppColors.primary)),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          _buildSearchField(),
          Expanded(
            child: _buildStudentList(filteredStudents),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStatItem(Icons.groups_outlined, '${widget.exam.studentCount} Öğrenci', Colors.purple),
          const SizedBox(width: 8),
          _buildStatItem(Icons.equalizer_rounded, 'Ort: 385.50', Colors.blue),
          const SizedBox(width: 8),
          _buildStatItem(Icons.verified_outlined, '%100 Başarı', Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'İsim veya numara ile ara...',
          prefixIcon: const Icon(Icons.search, size: 20),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStudentList(List<StudentResult> students) {
    if (students.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'Kayıtlı öğrenci yok.' : 'Öğrenci bulunamadı.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(StudentResult student) {
    final bool isWarning = student.status == 'warning';
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentReportScreen()),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isWarning ? Colors.orange.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isWarning ? Colors.orange.withOpacity(0.3) : Colors.grey[100]!,
            width: isWarning ? 2 : 1,
          ),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isWarning ? Colors.orange[100] : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  student.initials,
                  style: TextStyle(
                    color: isWarning ? Colors.orange[800] : AppColors.primary,
                    fontWeight: FontWeight.bold,
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
                    student.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  if (isWarning)
                    Row(
                      children: [
                        const Icon(Icons.warning_rounded, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'NO EKSİK',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'ÖĞRENCİ NO: ${student.studentNumber} • 8-A',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
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
                    fontSize: 18,
                    color: isWarning ? Colors.grey[400] : AppColors.primary,
                  ),
                ),
                if (!isWarning)
                  const Text(
                    'İLK %5',
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                if (isWarning)
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.orange[100],
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text(
                       'DÜZELT',
                       style: TextStyle(color: Colors.orange[900], fontSize: 10, fontWeight: FontWeight.w900),
                     ),
                   ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
