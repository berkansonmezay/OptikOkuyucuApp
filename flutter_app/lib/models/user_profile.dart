class UserProfile {
  String name;
  String email;
  String phone;
  String profileImageUrl;
  String institution;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
    required this.institution,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'profileImageUrl': profileImageUrl,
    'institution': institution,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? 'Sarah Jenkins',
    email: json['email'] ?? 'sarah@school.com',
    phone: json['phone'] ?? '+90 532 123 45 67',
    profileImageUrl: json['profileImageUrl'] ?? '',
    institution: json['institution'] ?? 'ÖĞRETMEN PORTALİ',
  );

  String get initials {
    if (name.isEmpty) return "??";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
