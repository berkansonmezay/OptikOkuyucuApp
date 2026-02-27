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
  final _maxScoreController = TextEditingController(text: '500');
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

  void _saveConfig() async {
    if (_selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir sınav seçiniz')));
      return;
    }

    final scoringData = {
      'minScore': double.tryParse(_minScoreController.text) ?? 0,
      'maxScore': double.tryParse(_maxScoreController.text) ?? 500,
      'netOption': _netOption,
      'subjectWeights': _weightControllers.map((key, controller) => MapEntry(key, double.tryParse(controller.text) ?? 1.0)),
    };

    _selectedExam!.scoring = scoringData;
    try {
      await context.read<ExamProvider>().updateExam(_selectedExam!.id, _selectedExam!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yapılandırma başarıyla kaydedildi')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Puanlama Yapılandırması', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('SINAV SEÇİN'),
            const SizedBox(height: 12),
            _buildExamSelector(),
            const SizedBox(height: 32),
            _buildSectionHeader('PUANLAMA ARALIĞI'),
            const SizedBox(height: 12),
            _buildScoreInputs(),
            const SizedBox(height: 32),
            _buildSectionHeader('NET HESAPLAMA SEÇENEĞİ'),
            const SizedBox(height: 12),
            _buildNetOptions(),
            const SizedBox(height: 32),
            _buildSectionHeader('DERS KATSAYILARI'),
            const SizedBox(height: 12),
            _buildWeightsList(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _saveConfig,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('YAPILANDIRMAYI KAYDET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: AppColors.primary.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.5,
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
            border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Exam>(
              isExpanded: true,
              hint: const Text('Bir sınav seçiniz...', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w700)),
              value: _selectedExam,
              icon: const Icon(Icons.unfold_more_rounded, color: AppColors.primary),
              items: examProvider.exams.map((exam) {
                return DropdownMenuItem(
                  value: exam,
                  child: Text('${exam.name} (${exam.type})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
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
    return Row(
      children: [
        Expanded(child: _buildScoreField(_minScoreController, 'MİN')),
        const SizedBox(width: 16),
        Expanded(child: _buildScoreField(_maxScoreController, 'MAKS')),
      ],
    );
  }

  Widget _buildScoreField(TextEditingController controller, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -1),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ],
      ),
    );
  }

  Widget _buildNetOptions() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildNetChip('3Y 1D', '3y1d'),
          _buildNetChip('4Y 1D', '4y1d'),
          _buildNetChip('Yok', 'yd'),
        ],
      ),
    );
  }

  Widget _buildNetChip(String label, String value) {
    final isSelected = _netOption == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _netOption = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildWeightItem('Türkçe', Icons.menu_book_rounded),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildWeightItem('Matematik', Icons.calculate_rounded),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildWeightItem('Fen Bilimleri', Icons.science_rounded),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildWeightItem('Sosyal Bilgiler', Icons.public_rounded),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildWeightItem('Din Kültürü', Icons.mosque_rounded),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF64748B), size: 18),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF475569))),
          const Spacer(),
          Container(
            width: 70,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
            ),
            child: TextField(
              controller: _weightControllers[label],
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
        ],
      ),
    );
  }
}
