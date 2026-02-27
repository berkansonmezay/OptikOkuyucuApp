import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/exam.dart';
import '../providers/exam_provider.dart';

class CreateExamScreen extends StatefulWidget {
  final Exam? editExam;
  const CreateExamScreen({super.key, this.editExam});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'LGS';
  List<Subject> _subjects = [];
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.editExam != null) {
      _nameController.text = widget.editExam!.name;
      _selectedDate = widget.editExam!.date;
      _selectedType = widget.editExam!.type;
      _subjects = List.from(widget.editExam!.subjects);
      _isManualMode = true;
    } else {
      _loadDefaultSubjects();
    }
  }

  void _loadDefaultSubjects() {
    final Map<String, List<Map<String, dynamic>>> defaults = {
      'LGS': [
        {'name': 'Türkçe', 'count': 20},
        {'name': 'Matematik', 'count': 20},
        {'name': 'Fen Bilimleri', 'count': 20},
        {'name': 'T.C. İnkılap Tarihi', 'count': 10},
        {'name': 'Din Kültürü', 'count': 10},
        {'name': 'Yabancı Dil', 'count': 10}
      ],
      'TYT': [
        {'name': 'Türkçe', 'count': 40},
        {'name': 'Sosyal Bilimler', 'count': 20},
        {'name': 'Temel Matematik', 'count': 40},
        {'name': 'Fen Bilimleri', 'count': 20}
      ],
      'AYT': [
        {'name': 'Türk Dili ve Ed.', 'count': 40},
        {'name': 'Matematik', 'count': 40},
        {'name': 'Fen Bilimleri', 'count': 40},
        {'name': 'Sosyal Bilimler II', 'count': 40}
      ]
    };

    final selectedDefaults = defaults[_selectedType] ?? [];
    setState(() {
      _subjects = selectedDefaults.map((d) => Subject(
        id: DateTime.now().millisecondsSinceEpoch.toString() + d['name'],
        name: d['name'] as String,
        questionCount: d['count'] as int,
        answers: List.filled(d['count'] as int, ''),
      )).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.editExam != null ? 'Sınavı Güncelle' : 'Yeni Sınav Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('SINAV TÜRÜ SEÇİN'),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 32),
            _buildSectionLabel('SINAV ADI'),
            const SizedBox(height: 12),
            _buildTextField(_nameController, 'Örn: 1. Dönem Genel Deneme'),
            const SizedBox(height: 32),
            _buildSectionLabel('SINAV TARİHİ'),
            const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 32),
            _buildCevapAnahtariHeader(),
            const SizedBox(height: 16),
            if (_isManualMode) _buildSubjectsList() else _buildExcelPlaceholder(),
            const SizedBox(height: 100), // Space for fixed button
          ],
        ),
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: ['LGS', 'TYT', 'AYT'].map((type) {
        bool isSelected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
                _loadDefaultSubjects();
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[200]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate)),
            const Icon(Icons.calendar_month_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCevapAnahtariHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel('CEVAP ANAHTARI'),
        Row(
          children: [
            _buildTabButton('EXCEL', !_isManualMode, () => setState(() => _isManualMode = false)),
            const SizedBox(width: 8),
            _buildTabButton('MANUEL', _isManualMode, () => setState(() => _isManualMode = true)),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildExcelPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.upload_file_rounded, size: 48, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Excel Yükleme henüz hazır değil', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Lütfen Manuel Giriş seçeneğini kullanın', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSubjectsList() {
    return Column(
      children: [
        ..._subjects.map((s) => _buildSubjectCard(s)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _subjects.add(Subject(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: '',
                questionCount: 20,
                answers: List.filled(20, ''),
              ));
            });
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('YENİ DERS EKLE'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Subject s) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[100]!),
      ),
      child: ExpansionTile(
        title: Text(s.name.isEmpty ? 'Yeni Seçilen Ders' : s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${s.questionCount} SORU TANIMLI', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        leading: Icon(Icons.menu_book_rounded, color: AppColors.primary.withOpacity(0.6)),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Basic Subject Settings
          Row(
            children: [
              Expanded(
                child: _buildTextField(TextEditingController(text: s.name)..addListener(() { s.name = _nameController.text; }), 'Ders Adı'),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Soru',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    int count = int.tryParse(val) ?? 0;
                    if (count > 0 && count <= 100) {
                      setState(() {
                        s.questionCount = count;
                        s.answers = List.filled(count, '');
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Here would be the answer bank, simplified for now
          const Text('Cevap anahtarı girişi mobil ekranda yakında geliştirilecektir.', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saveExam,
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Kaydet'),
        ),
      ),
    );
  }

  void _saveExam() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen sınav adı giriniz')));
      return;
    }

    final exam = Exam(
      id: widget.editExam?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      type: _selectedType,
      date: _selectedDate,
      subjects: _subjects,
    );

    if (widget.editExam != null) {
      context.read<ExamProvider>().updateExam(exam.id, exam);
    } else {
      context.read<ExamProvider>().addExam(exam);
    }

    Navigator.pop(context);
  }
}
