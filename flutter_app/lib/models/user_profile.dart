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
    profileImageUrl: json['profileImageUrl'] ?? 'https://i.pravatar.cc/150?img=32',
    institution: json['institution'] ?? 'ÖĞRETMEN PORTALİ',
  );
}
