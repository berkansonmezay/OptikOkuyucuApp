import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/exam.dart';

class StudentReportScreen extends StatelessWidget {
  final Exam exam;
  final StudentResult result;

  const StudentReportScreen({
    super.key,
    required this.exam,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Öğrenci Karnesi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentHeader(),
            const SizedBox(height: 32),
            _buildSummaryGrid(),
            const SizedBox(height: 32),
            _buildSuccessTable(),
            const SizedBox(height: 32),
            _buildProficiencySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 4),
          ),
          padding: const EdgeInsets.all(4),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF8FAFC),
            child: Text(
              result.initials,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 28),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'NO: ${result.studentNo}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kitapçık: ${result.booklet ?? "A"}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    // Calculate total net from rawStats if available
    double totalNet = 0;
    if (result.rawStats != null) {
      final stats = result.rawStats!;
      // Assume net is already calculated in rawStats for parity
      totalNet = (stats['totalNet'] as num?)?.toDouble() ?? 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SINAV ÖZETİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryCard('Puan', result.score.toStringAsFixed(3), AppColors.primary),
            const SizedBox(width: 12),
            _buildSummaryCard('Toplam Net', totalNet.toStringAsFixed(2), const Color(0xFF0F172A)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: const Color(0xFFF8FAFC),
            child: const Text('Ders Bazlı Başarı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          ),
          _buildTableHeader(),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...exam.subjects.map((subject) => _buildTableRow(subject)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text('Ders Adı', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8)))),
          _buildHeaderCol('D'),
          _buildHeaderCol('Y'),
          _buildHeaderCol('B'),
          _buildHeaderCol('Net', isAccent: true),
        ],
      ),
    );
  }

  Widget _buildHeaderCol(String text, {bool isAccent = false}) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isAccent ? AppColors.primary : const Color(0xFF94A3B8))),
      ),
    );
  }

  Widget _buildTableRow(Subject subject) {
    final stats = result.rawStats ?? {};
    final key = subject.name.toLowerCase().substring(0, 3);
    
    // Try to find matching stats using subject name or first 3 letters
    final d = stats['${key}_d'] ?? stats['${subject.name}_d'] ?? 0;
    final y = stats['${key}_y'] ?? stats['${subject.name}_y'] ?? 0;
    final b = subject.questionCount - (d as num) - (y as num);
    final net = (d as num).toDouble() - ((y as num).toDouble() / 3.0); // Simple 3y=1d logic as fallback

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(subject.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF475569)))),
              _buildDataCol(d.toString(), const Color(0xFF22C55E)),
              _buildDataCol(y.toString(), const Color(0xFFF87171)),
              _buildDataCol(b.toInt().toString(), const Color(0xFFCBD5E1)),
              _buildDataCol(net.toStringAsFixed(2), AppColors.primary, isBold: true),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF8FAFC)),
      ],
    );
  }

  Widget _buildDataCol(String text, Color color, {bool isBold = false}) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: color)),
      ),
    );
  }

  Widget _buildProficiencySection() {
    final stats = result.rawStats ?? {};
    final radarData = exam.subjects.map((sub) {
      final key = sub.name.toLowerCase().substring(0, 3);
      final d = stats['${key}_d'] ?? stats['${sub.name}_d'] ?? 0;
      final val = (sub.questionCount > 0) ? (d as num).toDouble() / sub.questionCount * 100 : 0.0;
      return RadarEntry(value: val);
    }).toList();

    if (radarData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('YETERLİLİK ANALİZİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          height: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: AppColors.softShadow,
          ),
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              getTitle: (index, angle) {
                final label = exam.subjects[index].name.length > 3 
                    ? exam.subjects[index].name.substring(0, 3).toUpperCase() 
                    : exam.subjects[index].name.toUpperCase();
                return RadarChartTitle(text: label, angle: angle);
              },
              radarBorderData: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
              tickBorderData: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
              gridBorderData: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              titlePositionPercentageOffset: 0.15,
              titleTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.primary.withOpacity(0.15),
                  borderColor: AppColors.primary,
                  borderWidth: 3,
                  entryRadius: 4,
                  dataEntries: radarData,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
