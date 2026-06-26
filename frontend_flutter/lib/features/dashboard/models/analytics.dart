class DashboardAnalytics {
  final int totalStudents;
  final int pendingApprovals;
  final int totalAssignments;
  final int totalSubmissions;
  final double completionPercentage;
  final int lateSubmissions;

  DashboardAnalytics({
    required this.totalStudents,
    required this.pendingApprovals,
    required this.totalAssignments,
    required this.totalSubmissions,
    required this.completionPercentage,
    required this.lateSubmissions,
  });

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) {
    return DashboardAnalytics(
      totalStudents: json['total_students'] as int? ?? 0,
      pendingApprovals: json['pending_approvals'] as int? ?? 0,
      totalAssignments: json['total_assignments'] as int? ?? 0,
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      completionPercentage: (json['completion_percentage'] as num? ?? 0.0).toDouble(),
      lateSubmissions: json['late_submissions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_students': totalStudents,
      'pending_approvals': pendingApprovals,
      'total_assignments': totalAssignments,
      'total_submissions': totalSubmissions,
      'completion_percentage': completionPercentage,
      'late_submissions': lateSubmissions,
    };
  }
}
