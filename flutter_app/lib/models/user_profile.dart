class UserProfile {
  String? id;
  String name;
  String email;
  String phone;
  String profileImageUrl;
  String institution;
  String role;

  UserProfile({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
    required this.institution,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'profileImageUrl': profileImageUrl,
    'institution': institution,
    'role': role,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    name: json['name'] ?? 'İsimsiz Kullanıcı',
    email: json['email'] ?? json['username'] ?? '',
    phone: json['phone'] ?? '',
    profileImageUrl: json['profileImageUrl'] ?? '',
    institution: json['institution'] ?? 'Bilinmiyor',
    role: json['role'] ?? 'user',
  );

  String get initials {
    if (name.isEmpty) return "??";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
