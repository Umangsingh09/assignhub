import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/supabase_storage_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../assignments/models/assignment.dart';
import '../../assignments/repositories/assignment_repository.dart';
import '../../submissions/models/submission.dart';
import '../../submissions/repositories/submission_repository.dart';

// Providers for dashboard lists
final studentAssignmentsProvider = FutureProvider.autoDispose<List<Assignment>>((ref) async {
  final repo = ref.watch(assignmentRepositoryProvider);
  return await repo.fetchAssignments();
});

final studentSubmissionsProvider = FutureProvider.autoDispose<List<Submission>>((ref) async {
  final repo = ref.watch(submissionRepositoryProvider);
  return await repo.fetchSubmissions();
});

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  Future<void> _refresh() async {
    ref.invalidate(studentAssignmentsProvider);
    ref.invalidate(studentSubmissionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);
    final submissionsAsync = ref.watch(studentSubmissionsProvider);
    final authState = ref.watch(authProvider);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 950;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.5),
        title: Text(
          'AssignHub Student',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Text(
            '@${authState.username ?? "Student"}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(width: 8),
          const Chip(
            label: Text('STUDENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primaryGlow,
            side: BorderSide.none,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        backgroundColor: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Assignments list
                    Expanded(
                      flex: 3,
                      child: _buildAssignmentsPanel(assignmentsAsync, submissionsAsync),
                    ),
                    const SizedBox(width: 24),
                    // Submissions history
                    Expanded(
                      flex: 2,
                      child: _buildSubmissionsPanel(submissionsAsync),
                    ),
                  ],
                )
              : ListView(
                  children: [
                    _buildAssignmentsPanel(assignmentsAsync, submissionsAsync),
                    const SizedBox(height: 24),
                    _buildSubmissionsPanel(submissionsAsync),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsPanel(
    AsyncValue<List<Assignment>> assignmentsAsync,
    AsyncValue<List<Submission>> submissionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Assignments',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 16),
        assignmentsAsync.when(
          data: (assignments) {
            if (assignments.isEmpty) {
              return const GlassCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No assignments posted yet.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              );
            }

            return submissionsAsync.when(
              data: (submissions) {
                // Map submissions by assignment ID
                final subMap = {for (var s in submissions) s.assignmentId: s};

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final a = assignments[index];
                    final sub = subMap[a.id];

                    return _buildAssignmentCard(a, sub);
                  },
                );
              },
              loading: () => _buildShimmerLoader(),
              error: (err, _) => Center(child: Text('Error loading submissions status: $err')),
            );
          },
          loading: () => _buildShimmerLoader(),
          error: (err, _) => Center(child: Text('Error loading assignments: $err')),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(Assignment a, Submission? sub) {
    final isPassed = a.deadline.isBefore(DateTime.now());
    
    Widget actionWidget;
    if (sub != null) {
      final isGraded = sub.status == 'graded';
      final isLate = sub.status == 'late';
      
      final badgeColor = isGraded
          ? AppColors.accent
          : (isLate ? AppColors.error : AppColors.warning);

      actionWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badgeColor.withOpacity(0.2)),
        ),
        child: Text(
          'Submitted (${sub.status.toUpperCase()})',
          style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      actionWidget = ElevatedButton(
        onPressed: () => _openSubmitDialog(a),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPassed ? AppColors.error.withOpacity(0.1) : AppColors.primary,
          foregroundColor: isPassed ? AppColors.error : Colors.white,
          side: isPassed ? const BorderSide(color: AppColors.error, width: 1) : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(isPassed ? 'Submit Late' : 'Submit Solution'),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  a.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              actionWidget,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Due: ${a.deadline.toLocal().toString().substring(0, 16)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (a.pdfUrl != null) ...[
                const Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    // Logic to open URL in browser
                  },
                  child: const Text(
                    'Reference PDF',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (a.externalLink != null) ...[
                const Icon(Icons.link, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    // Logic to open URL in browser
                  },
                  child: const Text(
                    'External Docs',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0.0);
  }

  Widget _buildSubmissionsPanel(AsyncValue<List<Submission>> submissionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Submissions Log',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 16),
        submissionsAsync.when(
          data: (submissions) {
            if (submissions.isEmpty) {
              return const GlassCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No submissions recorded.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              );
            }

            return GlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Assignment')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: submissions.map((s) {
                      final isGraded = s.status == 'graded';
                      final isLate = s.status == 'late';
                      
                      final badgeColor = isGraded
                          ? AppColors.accent
                          : (isLate ? AppColors.error : AppColors.warning);

                      return DataRow(cells: [
                        DataCell(Text(s.assignmentTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(s.submittedAt.toLocal().toString().substring(0, 10))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: badgeColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              s.status.toUpperCase(),
                              style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          },
          loading: () => _buildShimmerLoader(),
          error: (err, _) => Center(child: Text('Error loading submissions: $err')),
        ),
      ],
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBg,
      highlightColor: AppColors.cardBgHover,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => Container(
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _openSubmitDialog(Assignment a) {
    showDialog(
      context: context,
      builder: (context) => SubmitSolutionDialog(
        assignment: a,
        onSuccess: () {
          _refresh();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// MODAL DIALOG: Submit Solution
// -------------------------------------------------------------
class SubmitSolutionDialog extends ConsumerStatefulWidget {
  final Assignment assignment;
  final VoidCallback onSuccess;

  const SubmitSolutionDialog({
    Key? key,
    required this.assignment,
    required this.onSuccess,
  }) : super(key: key);

  @override
  ConsumerState<SubmitSolutionDialog> createState() => _SubmitSolutionDialogState();
}

class _SubmitSolutionDialogState extends ConsumerState<SubmitSolutionDialog> {
  final _textController = TextEditingController();
  PlatformFile? _selectedFile;
  
  bool _isUploading = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'zip', 'txt', 'png', 'jpg'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'File picking failed: $e';
      });
    }
  }

  Future<void> _handleSubmit() async {
    final textVal = _textController.text.trim();
    if (textVal.isEmpty && _selectedFile == null) {
      setState(() {
        _error = 'Please write a text response or select a file to upload.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      String? fileUrl;
      
      // Upload file to Supabase if selected
      if (_selectedFile != null) {
        List<int> fileBytes;
        if (kIsWeb) {
          fileBytes = _selectedFile!.bytes!;
        } else {
          final file = File(_selectedFile!.path!);
          fileBytes = await file.readAsBytes();
        }

        final storageClient = SupabaseStorageClient();
        fileUrl = await storageClient.uploadFile(
          bucketName: 'submissions',
          fileBytes: fileBytes,
          fileName: _selectedFile!.name,
          mimeType: _selectedFile!.name.endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream',
        );
      }

      // Submit to backend
      final submissionRepo = ref.read(submissionRepositoryProvider);
      await submissionRepo.createSubmission({
        'assignment': widget.assignment.id,
        'text_submission': textVal.isNotEmpty ? textVal : null,
        'file_url': fileUrl,
      });

      widget.onSuccess();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Submit Solution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.assignment.title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              // Text submission field
              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Text Submission / Comments (Optional)',
                  hintText: 'Enter comments or link to GitHub repository...',
                  alignLabelWithHint: true,
                ),
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),

              // File Picker section
              InkWell(
                onTap: _isUploading ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedFile != null ? AppColors.accent.withOpacity(0.4) : AppColors.cardBorder,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle_outline_rounded : Icons.upload_file_outlined,
                        size: 32,
                        color: _selectedFile != null ? AppColors.accent : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null ? _selectedFile!.name : 'Select file (PDF, ZIP, TXT)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                          color: _selectedFile != null ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isUploading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _handleSubmit,
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Solution'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
