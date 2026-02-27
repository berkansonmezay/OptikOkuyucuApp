import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/exam.dart';
import '../providers/exam_provider.dart';
import '../providers/user_provider.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.editExam != null ? 'Sınavı Güncelle' : 'Yeni Sınav Oluştur', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
            _buildSectionLabel('SINAV TÜRÜ SEÇİN'),
            const SizedBox(height: 16),
            _buildTypeSelector(),
            const SizedBox(height: 32),
            _buildSectionLabel('SINAV ADI'),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Örn: 1. Dönem Genel Deneme'),
            const SizedBox(height: 32),
            _buildSectionLabel('SINAV TARİHİ'),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 32),
            _buildCevapAnahtariHeader(),
            const SizedBox(height: 16),
            if (_isManualMode) _buildSubjectsList() else _buildExcelPlaceholder(),
            const SizedBox(height: 120), // Space for bottom button
          ],
        ),
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected ? [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
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
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.primary),
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTabButton('EXCEL', !_isManualMode, () => setState(() => _isManualMode = false)),
              _buildTabButton('MANUEL', _isManualMode, () => setState(() => _isManualMode = true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: active ? AppColors.primary : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildExcelPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.upload_file_rounded, size: 40, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 20),
          const Text('Excel Yükleme', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Excel dosyası ile cevap anahtarı yükleme mobil sürümde yakında eklenecektir.', 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
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
                questionCount: 0,
                answers: [],
              ));
            });
          },
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: const Text('YENİ DERS EKLE'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: Color(0xFFDDD6FE), width: 2),
            backgroundColor: const Color(0xFFF5F3FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Subject s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(s.name.isEmpty ? 'Yeni Seçilen Ders' : s.name.toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
        subtitle: Text('${s.questionCount} SORU TANIMLI', 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF64748B), size: 20),
        ),
        trailing: const Icon(Icons.expand_more_rounded, color: Color(0xFFCBD5E1)),
        shape: const Border.fromBorderSide(BorderSide.none),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => s.name = val),
                    decoration: const InputDecoration(
                      hintText: 'Ders Adı',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 70,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final q = int.tryParse(val) ?? 0;
                    setState(() {
                      s.questionCount = q;
                      s.answers = List.filled(q, '');
                    });
                  },
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Soru',
                    hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Cevap anahtarı girişi web üzerinden yapılmalıdır.', 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _saveExam,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: const Text('KAYDET VE DEVAM ET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      ),
    );
  }

  void _saveExam() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen sınav adı giriniz')));
      return;
    }

    final exam = Exam(
      id: widget.editExam?.id ?? '',
      name: _nameController.text,
      type: _selectedType,
      date: _selectedDate,
      subjects: _subjects,
    );

    try {
      if (widget.editExam != null && widget.editExam!.id.isNotEmpty) {
        await context.read<ExamProvider>().updateExam(exam.id, exam);
      } else {
        final creatorId = context.read<UserProvider>().user?.id ?? '';
        await context.read<ExamProvider>().addExam(exam, creatorId);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}
