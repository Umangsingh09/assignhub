class StudentProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String rollNumber;
  final bool isApproved;
  final bool isActive;

  StudentProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.rollNumber,
    required this.isApproved,
    required this.isActive,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      rollNumber: json['roll_number'] as String? ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'roll_number': rollNumber,
      'is_approved': isApproved,
      'is_active': isActive,
    };
  }
}
