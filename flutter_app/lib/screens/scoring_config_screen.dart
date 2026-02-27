import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/exam_provider.dart';
import '../providers/scoring_provider.dart';
import '../models/scoring_config.dart';
import '../models/exam.dart';

class ScoringConfigScreen extends StatefulWidget {
  const ScoringConfigScreen({super.key});

  @override
  State<ScoringConfigScreen> createState() => _ScoringConfigScreenState();
}

class _ScoringConfigScreenState extends State<ScoringConfigScreen> {
  Exam? _selectedExam;
  final _minScoreController = TextEditingController(text: '0');
  final _maxScoreController = TextEditingController(text: '100');
  String _netOption = '3y1d';
  final Map<String, TextEditingController> _weightControllers = {
    'Türkçe': TextEditingController(text: '4.0'),
    'Matematik': TextEditingController(text: '4.0'),
    'Fen Bilimleri': TextEditingController(text: '4.0'),
    'Sosyal Bilgiler': TextEditingController(text: '1.0'),
    'Din Kültürü': TextEditingController(text: '1.0'),
    'İngilizce': TextEditingController(text: '1.0'),
  };

  @override
  void dispose() {
    _minScoreController.dispose();
    _maxScoreController.dispose();
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onExamChanged(Exam? exam) {
    if (exam == null) return;
    setState(() {
      _selectedExam = exam;
      if (exam.scoring != null) {
        final scoring = exam.scoring!;
        _minScoreController.text = (scoring['minScore'] ?? 0).toString();
        _maxScoreController.text = (scoring['maxScore'] ?? 500).toString();
        _netOption = scoring['netOption'] ?? '3y1d';
        final weights = scoring['subjectWeights'] as Map<String, dynamic>?;
        if (weights != null) {
          weights.forEach((key, value) {
            if (_weightControllers.containsKey(key)) {
              _weightControllers[key]!.text = value.toString();
            }
          });
        }
      } else {
        // Set defaults for LGS if type is LGS
        if (exam.type == 'LGS') {
           _maxScoreController.text = '500';
           _weightControllers['Türkçe']!.text = '4.0';
           _weightControllers['Matematik']!.text = '4.0';
           _weightControllers['Fen Bilimleri']!.text = '4.0';
           _weightControllers['Sosyal Bilgiler']!.text = '1.0';
           _weightControllers['Din Kültürü']!.text = '1.0';
           _weightControllers['İngilizce']!.text = '1.0';
        }
      }
    });
  }

  void _saveConfig() {
    if (_selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir sınav seçiniz')),
      );
      return;
    }

    final scoringData = {
      'minScore': double.tryParse(_minScoreController.text) ?? 0,
      'maxScore': double.tryParse(_maxScoreController.text) ?? 500,
      'netOption': _netOption,
      'subjectWeights': _weightControllers.map((key, controller) => MapEntry(key, double.tryParse(controller.text) ?? 1.0)),
    };

    _selectedExam!.scoring = scoringData;
    context.read<ExamProvider>().updateExam(_selectedExam!.id, _selectedExam!);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yapılandırma kaydedildi')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFF),
      appBar: AppBar(
        title: const Text('Puanlama Yapılandırması'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('SINAV SEÇİN'),
            _buildExamSelector(),
            const SizedBox(height: 28),
            _buildSectionHeader('PUANLAMA İŞLEMLERİ'),
            _buildScoreInputs(),
            const SizedBox(height: 28),
            _buildSectionHeader('NET HESAPLAMA'),
            _buildNetOptions(),
            const SizedBox(height: 28),
            _buildSectionHeader('DERS KATSAYILARI (AĞIRLIK)'),
            _buildWeightsList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveConfig,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.black26,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildExamSelector() {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Exam>(
              isExpanded: true,
              hint: const Text('Bir sınav seçiniz...', style: TextStyle(color: Colors.black26, fontSize: 14, fontWeight: FontWeight.bold)),
              value: _selectedExam,
              icon: const Icon(Icons.unfold_more_rounded, color: Colors.black12),
              items: examProvider.exams.map((exam) {
                return DropdownMenuItem(
                  value: exam,
                  child: Text('${exam.name} (${exam.type})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                );
              }).toList(),
              onChanged: _onExamChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreInputs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('MİNİMUM PUAN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black26)),
                const SizedBox(height: 8),
                _buildScoreField(_minScoreController),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                const Text('MAKSİMUM PUAN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black26)),
                const SizedBox(height: 8),
                _buildScoreField(_maxScoreController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreField(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  Widget _buildNetOptions() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          _buildNetChip('3 Yanlış 1 Doğru', '3y1d'),
          _buildNetChip('4 Yanlış 1 Doğru', '4y1d'),
          _buildNetChip('- Yanlış - Doğru', 'yd'),
        ],
      ),
    );
  }

  Widget _buildNetChip(String label, String value) {
    final isSelected = _netOption == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _netOption = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : Colors.black26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          _buildWeightItem('Türkçe', Icons.menu_book_rounded),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          _buildWeightItem('Matematik', Icons.calculate_rounded),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          _buildWeightItem('Fen Bilimleri', Icons.science_rounded),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          _buildWeightItem('Sosyal Bilgiler', Icons.public_rounded),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          _buildWeightItem('Din Kültürü', Icons.mosque_rounded),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          _buildWeightItem('İngilizce', Icons.language_rounded),
        ],
      ),
    );
  }

  Widget _buildWeightItem(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
          const Spacer(),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 0),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _weightControllers[label],
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
