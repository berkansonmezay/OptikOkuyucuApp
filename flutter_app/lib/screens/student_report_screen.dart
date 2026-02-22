import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/app_colors.dart';

class StudentReportScreen extends StatelessWidget {
  const StudentReportScreen({super.key});

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
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emirhan Soydan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              SizedBox(height: 4),
              Text(
                '12-A Sınıfı • No: 452',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
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
            'Konu Dağılım Analizi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                getTitle: (index, angle) {
                  const titles = ['Matematik', 'Türkçe', 'Fen', 'Sosyal', 'İngilizce'];
                  return RadarChartTitle(text: titles[index], angle: angle);
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withOpacity(0.2),
                    borderColor: AppColors.primary,
                    entryRadius: 3,
                    dataEntries: [
                      const RadarEntry(value: 85),
                      const RadarEntry(value: 70),
                      const RadarEntry(value: 90),
                      const RadarEntry(value: 65),
                      const RadarEntry(value: 80),
                    ],
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
        _buildScoreCard('LGS PUANI', '482.450', AppColors.primary),
        const SizedBox(width: 12),
        _buildScoreCard('GENEL SIRA', '12 / 450', Colors.blue),
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
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ders Bazlı Detaylar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildStatRow('Türkçe', '18 DOĞRU', '2 YANLIŞ', 0.9),
          const Divider(height: 32),
          _buildStatRow('Matematik', '15 DOĞRU', '5 YANLIŞ', 0.75),
          const Divider(height: 32),
          _buildStatRow('Fen Bilimleri', '20 DOĞRU', '0 YANLIŞ', 1.0),
        ],
      ),
    );
  }

  Widget _buildStatRow(String subject, String d, String y, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Row(
              children: [
                Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green)),
                const SizedBox(width: 8),
                Text(y, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
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
