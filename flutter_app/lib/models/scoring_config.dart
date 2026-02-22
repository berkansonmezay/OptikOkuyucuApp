class ScoringConfig {
  final double minScore;
  final double maxScore;
  final String netOption;
  final Map<String, double> subjectWeights;

  ScoringConfig({
    required this.minScore,
    required this.maxScore,
    required this.netOption,
    required this.subjectWeights,
  });

  Map<String, dynamic> toJson() => {
    'minScore': minScore,
    'maxScore': maxScore,
    'netOption': netOption,
    'subjectWeights': subjectWeights,
  };

  factory ScoringConfig.fromJson(Map<String, dynamic> json) => ScoringConfig(
    minScore: (json['minScore'] ?? 0.0).toDouble(),
    maxScore: (json['maxScore'] ?? 100.0).toDouble(),
    netOption: json['netOption'] ?? '3y1d',
    subjectWeights: Map<String, double>.from(json['subjectWeights'] ?? {
      'Türkçe': 4.0,
      'Matematik': 4.0,
      'Fen Bilimleri': 3.0,
      'Sosyal Bilgiler': 2.0,
    }),
  );
}
