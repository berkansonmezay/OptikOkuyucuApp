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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Öğrenci Karnesi'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStudentInfo(),
            const SizedBox(height: 24),
            _buildRadarChart(),
            const SizedBox(height: 24),
            _buildScoreSection(),
            const SizedBox(height: 24),
            _buildDetailedStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(result.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.studentName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              const SizedBox(height: 4),
              Text(
                'No: ${result.studentNumber} • Kitapçık: ${result.bookType ?? "A"}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    // Collect stats from rawStats if available
    final stats = result.rawStats ?? {};
    final subjects = ['Türkçe', 'Matematik', 'Fen', 'Sosyal', 'Din', 'İng'];
    final data = subjects.map((s) {
      final val = stats[s.toLowerCase()]; // simplified check
      return RadarEntry(value: (val is num) ? val.toDouble() : 50.0);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Başarı Analizi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                getTitle: (index, angle) {
                  return RadarChartTitle(text: subjects[index], angle: angle);
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withOpacity(0.2),
                    borderColor: AppColors.primary,
                    entryRadius: 3,
                    dataEntries: data,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection() {
    return Row(
      children: [
        _buildScoreCard('${exam.type} PUANI', result.score.toStringAsFixed(3), AppColors.primary),
        const SizedBox(width: 12),
        _buildScoreCard('SINAV TARİHİ', DateFormat('dd.MM.yyyy').format(exam.date), Colors.blue),
      ],
    );
  }

  Widget _buildScoreCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            FittedBox(child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color))),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    final stats = result.rawStats ?? {};
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ders Bazlı Detaylar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildStatRow('Türkçe', stats['tur_d'] ?? 0, stats['tur_y'] ?? 0, 20),
          const Divider(height: 32),
          _buildStatRow('Matematik', stats['mat_d'] ?? 0, stats['mat_y'] ?? 0, 20),
          const Divider(height: 32),
          _buildStatRow('Fen Bilimleri', stats['fen_d'] ?? 0, stats['fen_y'] ?? 0, 20),
          const Divider(height: 32),
          _buildStatRow('Sosyal Bilgiler', stats['sos_d'] ?? 0, stats['sos_y'] ?? 0, 10),
        ],
      ),
    );
  }

  Widget _buildStatRow(String subject, dynamic d, dynamic y, int total) {
    final dCount = (d is num) ? d.toInt() : 0;
    final yCount = (y is num) ? y.toInt() : 0;
    final progress = total > 0 ? dCount / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Row(
              children: [
                Text('$dCount DOĞRU', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green)),
                const SizedBox(width: 8),
                Text('$yCount YANLIŞ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? AppColors.green : AppColors.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
