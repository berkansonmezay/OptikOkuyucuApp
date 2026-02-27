class Exam {
  final String id;
  String name;
  String type;
  DateTime date;
  int studentCount;
  String status;
  List<Subject> subjects;
  List<StudentResult> students;
  String? creatorId;
  Map<String, dynamic>? scoring;

  Exam({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    this.studentCount = 0,
    this.status = 'pending',
    required this.subjects,
    this.students = const [],
    this.creatorId,
    this.scoring,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'date': date.toIso8601String().split('T')[0], // Match web YYYY-MM-DD
    'studentCount': studentCount,
    'status': status,
    'subjects': subjects.map((s) => s.toJson()).toList(),
    'creatorId': creatorId,
    'scoring': scoring,
  };

  factory Exam.fromJson(Map<String, dynamic> json, String docId) => Exam(
    id: docId,
    name: json['name'] ?? '',
    type: json['type'] ?? 'LGS',
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    studentCount: json['studentCount'] ?? 0,
    status: json['status'] ?? 'pending',
    subjects: json['subjects'] != null 
        ? (json['subjects'] as List).map((s) => Subject.fromJson(s)).toList()
        : [],
    creatorId: json['creatorId'],
    scoring: json['scoring'],
  );
}

class StudentResult {
  final String id;
  final String name;
  final String studentNo;
  final double score;
  final String? booklet;
  final String? rawAnswers;
  final Map<String, dynamic>? rawStats;
  final String? tcNo;
  final String? className;
  final String? errorMessage;

  StudentResult({
    required this.id,
    required this.name,
    required this.studentNo,
    required this.score,
    this.booklet,
    this.rawAnswers,
    this.rawStats,
    this.tcNo,
    this.className,
    this.errorMessage,
  });

  String get initials {
    if (name.isEmpty) return '??';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts.last[0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'studentNo': studentNo,
    'score': score,
    'booklet': booklet,
    'rawAnswers': rawAnswers,
    'rawStats': rawStats,
    'tcNo': tcNo,
    'className': className,
    'errorMessage': errorMessage,
  };

  factory StudentResult.fromJson(Map<String, dynamic> json, String docId) => StudentResult(
    id: docId,
    name: json['name'] ?? '',
    studentNo: json['studentNo'] ?? '',
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
    booklet: json['booklet'],
    rawAnswers: json['rawAnswers'],
    rawStats: json['rawStats'] ?? json,
    tcNo: json['tcNo'],
    className: json['className'],
    errorMessage: json['errorMessage'],
  );
}

class Subject {
  final String? id; // Web uses Date.now() usually
  String name;
  int questionCount;
  List<String> answers;

  Subject({
    this.id,
    required this.name,
    required this.questionCount,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'questionCount': questionCount,
    'answers': answers,
  };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id']?.toString(),
    name: json['name'] ?? '',
    questionCount: json['questionCount'] ?? 0,
    answers: json['answers'] != null ? List<String>.from(json['answers']) : [],
  );
}
