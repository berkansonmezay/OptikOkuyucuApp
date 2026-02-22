class Exam {
  final String id;
  String name;
  String type;
  DateTime date;
  int studentCount;
  String status;
  List<Subject> subjects;
  List<StudentResult> students;

  Exam({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    this.studentCount = 0,
    this.status = 'pending',
    required this.subjects,
    this.students = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'date': date.toIso8601String(),
    'studentCount': studentCount,
    'status': status,
    'subjects': subjects.map((s) => s.toJson()).toList(),
    'students': students.map((s) => s.toJson()).toList(),
  };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    date: DateTime.parse(json['date']),
    studentCount: json['studentCount'],
    status: json['status'],
    subjects: (json['subjects'] as List).map((s) => Subject.fromJson(s)).toList(),
    students: json['students'] != null 
        ? (json['students'] as List).map((s) => StudentResult.fromJson(s)).toList()
        : [],
  );
}

class StudentResult {
  final String id;
  final String studentName;
  final String studentNumber;
  final double score;
  final String status; // 'success', 'warning' (missing info)
  final String? bookType;

  StudentResult({
    required this.id,
    required this.studentName,
    required this.studentNumber,
    required this.score,
    required this.status,
    this.bookType,
  });

  String get initials {
    if (studentName.isEmpty) return '??';
    List<String> parts = studentName.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts.last[0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentName': studentName,
    'studentNumber': studentNumber,
    'score': score,
    'status': status,
    'bookType': bookType,
  };

  factory StudentResult.fromJson(Map<String, dynamic> json) => StudentResult(
    id: json['id'],
    studentName: json['studentName'],
    studentNumber: json['studentNumber'],
    score: (json['score'] as num).toDouble(),
    status: json['status'],
    bookType: json['bookType'],
  );
}

class Subject {
  final String id;
  String name;
  int questionCount;
  List<String> answers;

  Subject({
    required this.id,
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
    id: json['id'],
    name: json['name'],
    questionCount: json['questionCount'],
    answers: List<String>.from(json['answers']),
  );
}
