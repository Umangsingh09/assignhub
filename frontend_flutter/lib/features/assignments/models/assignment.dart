class Assignment {
  final int id;
  final String title;
  final String description;
  final String? pdfUrl;
  final String? externalLink;
  final DateTime deadline;
  final int createdBy;
  final String createdByUsername;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    this.pdfUrl,
    this.externalLink,
    required this.deadline,
    required this.createdBy,
    required this.createdByUsername,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      pdfUrl: json['pdf_url'] as String?,
      externalLink: json['external_link'] as String?,
      deadline: DateTime.parse(json['deadline'] as String),
      createdBy: json['created_by'] as int,
      createdByUsername: json['created_by_username'] as String? ?? 'Admin',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pdf_url': pdfUrl,
      'external_link': externalLink,
      'deadline': deadline.toIso8601String(),
      'created_by': createdBy,
      'created_by_username': createdByUsername,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
