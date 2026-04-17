import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/students/controllers/student_controller.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/views/student_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({super.key});

  @override
  State<StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<StudentsView> {
  late final StudentController _controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClass;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _controller = StudentController();
    _controller.loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showStudentForm([Student? student]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StudentFormDialog(
        student: student,
        controller: _controller,
      ),
    );
  }

  Future<void> _handleDelete(Student student) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}? This action cannot be fully undone here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controller.deleteStudent(student.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureSvc = AppServices.instance.featureAccessService;
    if (featureSvc == null || !featureSvc.canAccess('student_view')) {
      return const Center(child: Text('Access Denied. Missing "student_view" permission.'));
    }

    final cs = Theme.of(context).colorScheme;
    final canCreate = featureSvc.canAccess('student_create');

    return ControllerBuilder<StudentController>(
      controller: _controller,
      builder: (context, controller, _) {
        return Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or phone...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) {
                        controller.setSearchQuery(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedClass,
                        hint: const Text('All Classes'),
                        items: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedClass = val);
                          controller.setFilter(_selectedClass, _selectedStatus);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (canCreate)
                    FilledButton.icon(
                      onPressed: () => _showStudentForm(),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Add Student'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: controller.busy && controller.students.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : controller.students.isEmpty
                      ? Center(
                          child: Text(
                            'No students found',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                          itemCount: controller.students.length + (controller.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == controller.students.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final student = controller.students[index];
                            final isActive = student.status == 'active';

                            return Container(
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : '?',
                                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${student.className} • ${student.phone}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        student.status.toUpperCase(),
                                        style: TextStyle(
                                          color: isActive ? Colors.green : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          if (featureSvc.canAccess('student_update')) {
                                            _showStudentForm(student);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Permission denied.')),
                                            );
                                          }
                                        } else if (val == 'delete') {
                                          _handleDelete(student);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        if (featureSvc.canAccess('student_delete'))
                                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
