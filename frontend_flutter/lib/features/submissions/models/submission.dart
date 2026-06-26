class Submission {
  final int id;
  final int assignmentId;
  final String assignmentTitle;
  final int studentId;
  final String studentUsername;
  final String? fileUrl;
  final String? textSubmission;
  final DateTime submittedAt;
  final String status;
  final bool isLate;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.studentId,
    required this.studentUsername,
    this.fileUrl,
    this.textSubmission,
    required this.submittedAt,
    required this.status,
    required this.isLate,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as int,
      assignmentId: json['assignment'] as int,
      assignmentTitle: json['assignment_title'] as String? ?? 'Assignment',
      studentId: json['student'] as int,
      studentUsername: json['student_username'] as String? ?? 'Student',
      fileUrl: json['file_url'] as String?,
      textSubmission: json['text_submission'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      status: json['status'] as String? ?? 'pending',
      isLate: json['is_late'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment': assignmentId,
      'assignment_title': assignmentTitle,
      'student': studentId,
      'student_username': studentUsername,
      'file_url': fileUrl,
      'text_submission': textSubmission,
      'submitted_at': submittedAt.toIso8601String(),
      'status': status,
      'is_late': isLate,
    };
  }
}
