class Exam {
  final String id;
  String name;
  String type;
  DateTime date;
  int studentCount;
  String status;
  List<Subject> subjects;

  Exam({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    this.studentCount = 0,
    this.status = 'pending',
    required this.subjects,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'date': date.toIso8601String(),
    'studentCount': studentCount,
    'status': status,
    'subjects': subjects.map((s) => s.toJson()).toList(),
  };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    date: DateTime.parse(json['date']),
    studentCount: json['studentCount'],
    status: json['status'],
    subjects: (json['subjects'] as List).map((s) => Subject.fromJson(s)).toList(),
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
