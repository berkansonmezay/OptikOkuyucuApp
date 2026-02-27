import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/exam_provider.dart';
import '../models/exam.dart';
import 'exam_results_screen.dart';
import '../core/app_colors.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sınav Sonuçları', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textMain)),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TAMAMLANAN SINAVLAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[400],
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
          Expanded(child: _buildResultsList(context)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Sonuçlarda ara...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredExams = provider.exams.where((exam) {
          return exam.name.toLowerCase().contains(_searchQuery) ||
              exam.type.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredExams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[100]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'Henüz kaydedilmiş sınav yok.' : 'Sonuç bulunamadı.',
                  style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: filteredExams.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildResultCard(context, filteredExams[index]);
          },
        );
      },
    );
  }

  Widget _buildResultCard(BuildContext context, Exam exam) {
    Color statusColor = AppColors.primary;
    Color bgColor = AppColors.primary.withOpacity(0.05);
    Color typeBg = const Color(0xFFF5F3FF);
    Color typeText = AppColors.primary;

    if (exam.type == 'LGS') {
      statusColor = AppColors.green;
      bgColor = AppColors.green.withOpacity(0.05);
      typeBg = const Color(0xFFECFDF5);
      typeText = AppColors.green;
    } else if (exam.type == 'TYT') {
      statusColor = AppColors.orange;
      bgColor = AppColors.orange.withOpacity(0.05);
      typeBg = const Color(0xFFFFF7ED);
      typeText = AppColors.orange;
    }

    final formattedDate = DateFormat('dd MMM yyyy', 'tr_TR').format(exam.date);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ExamResultsScreen(exam: exam)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          color: Colors.white,
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
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.analytics_rounded, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exam.type,
                          style: TextStyle(
                            color: typeText,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exam.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textMain),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInfoBadge(Icons.group_rounded, '${exam.studentCount} Öğrenci'),
                      const SizedBox(width: 8),
                      _buildInfoBadge(Icons.calendar_today_rounded, formattedDate),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '---',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13),
                ),
                Text(
                  'ORTALAMA',
                  style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
