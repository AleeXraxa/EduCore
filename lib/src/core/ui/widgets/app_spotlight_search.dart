import 'dart:ui';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/exams/models/exam.dart';
import 'package:flutter/material.dart';

class AppSpotlightSearch extends StatefulWidget {
  const AppSpotlightSearch({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Spotlight Search',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AppSpotlightSearch();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AppSpotlightSearch> createState() => _AppSpotlightSearchState();
}

class _AppSpotlightSearchState extends State<AppSpotlightSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<Student> _students = [];
  List<Fee> _fees = [];
  List<Exam> _exams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _students = [];
        _fees = [];
        _exams = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final academyId = AppServices.instance.authService!.session!.academyId;
      
      // Parallel searches using services
      final results = await Future.wait([
        AppServices.instance.studentService!.getStudents(academyId, limit: 10, name: query),
        AppServices.instance.feeService!.getFees(academyId, limit: 10),
        AppServices.instance.examService!.getExams(academyId, limit: 10),
      ]);

      if (!mounted) return;

      final studentResults = (results[0] as List<Student>).take(5).toList();
      final feeResults = (results[1] as List<Fee>)
          .where((f) => f.title.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
      final examResults = (results[2] as List<Exam>)
          .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();

      setState(() {
        _students = studentResults;
        _fees = feeResults;
        _exams = examResults;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 600,
        margin: const EdgeInsets.only(top: 100),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: cs.primary, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onChanged: _performSearch,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'Search students, fees, exams...',
                                hintStyle: TextStyle(
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ESC',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Results
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _searchController.text.isEmpty
                              ? _buildQuickActions(context)
                              : _buildSearchResults(context),
                    ),

                    // Footer
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const _HintItem(icon: Icons.keyboard_arrow_up_rounded, label: 'Navigate'),
                          const SizedBox(width: 16),
                          const _HintItem(icon: Icons.keyboard_return_rounded, label: 'Open'),
                          const Spacer(),
                          Text(
                            'EduCore Spotlight',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: cs.primary.withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK NAVIGATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            icon: Icons.dashboard_rounded,
            label: 'Go to Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          _QuickActionTile(
            icon: Icons.people_rounded,
            label: 'Student Directory',
            onTap: () => Navigator.pop(context),
          ),
          _QuickActionTile(
            icon: Icons.payments_rounded,
            label: 'Fee Records',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_students.isEmpty && _fees.isEmpty && _exams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: Text('No results found.', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      children: [
        if (_students.isNotEmpty) ...[
          const _ResultSectionHeader(label: 'STUDENTS'),
          ..._students.map((s) => _ResultTile(
                title: s.name,
                subtitle: 'Roll No: ${s.rollNo} • ${s.className}',
                icon: Icons.person_rounded,
                onTap: () => Navigator.pop(context),
              )),
        ],
        if (_fees.isNotEmpty) ...[
          const _ResultSectionHeader(label: 'FEES'),
          ..._fees.map((f) => _ResultTile(
                title: f.title,
                subtitle: '${f.studentName} • Rs. ${f.amount}',
                icon: Icons.payments_rounded,
                onTap: () => Navigator.pop(context),
              )),
        ],
        if (_exams.isNotEmpty) ...[
          const _ResultSectionHeader(label: 'EXAMS'),
          ..._exams.map((e) => _ResultTile(
                title: e.name,
                subtitle: e.className ?? '-',
                icon: Icons.assignment_rounded,
                onTap: () => Navigator.pop(context),
              )),
        ],
      ],
    );
  }
}

class _ResultSectionHeader extends StatelessWidget {
  const _ResultSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _HintItem extends StatelessWidget {
  const _HintItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
