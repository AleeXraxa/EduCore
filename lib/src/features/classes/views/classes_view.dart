import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/features/classes/classes_controller.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/classes/widgets/add_edit_class_dialog.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/features/classes/views/class_details_view.dart';
import 'package:flutter/material.dart';

class ClassesView extends StatefulWidget {
  const ClassesView({super.key});

  @override
  State<ClassesView> createState() => _ClassesViewState();
}

class _ClassesViewState extends State<ClassesView> {
  late final ClassesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClassesController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<ClassesController>(
      controller: _controller,
      builder: (context, controller, child) {
        final cs = Theme.of(context).colorScheme;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAnimatedSlide(
                delayIndex: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Management',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.2,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Define classes, sections, and assign class teachers.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    AppSearchField(
                      width: 320, 
                      hintText: 'Search classes...',
                      onChanged: controller.setSearchQuery,
                    ),
                    const SizedBox(width: 16),
                    if (controller.canCreate)
                      AppPrimaryButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddEditClassDialog(controller: controller),
                          );
                        },
                        icon: Icons.add_rounded,
                        label: 'Add Class',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              if (controller.busy && controller.classes.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (controller.errorMessage != null && controller.classes.isEmpty)
                Center(child: Text(controller.errorMessage!, style: TextStyle(color: cs.error)))
              else if (controller.classes.isEmpty)
                AppAnimatedSlide(
                  delayIndex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(48),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: AppRadii.r24,
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.class_outlined, size: 64, color: cs.primary.withValues(alpha: 0.2)),
                        const SizedBox(height: 24),
                        Text(
                          controller.searchQuery?.isNotEmpty == true ? 'No matches found' : 'No Classes Defined',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.searchQuery?.isNotEmpty == true 
                              ? 'Try adjusting your search criteria.'
                              : 'Get started by creating your first class and adding sections.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 32),
                        if (controller.canCreate && (controller.searchQuery?.isEmpty ?? true))
                          AppPrimaryButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddEditClassDialog(controller: controller),
                              );
                            },
                            label: 'Create First Class',
                          ),
                      ],
                    ),
                  ),
                )
              else
                AppAnimatedSlide(
                  delayIndex: 1,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisExtent: 200,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: controller.classes.length,
                    itemBuilder: (context, index) {
                      final cls = controller.classes[index];
                      return _ClassCard(classData: cls, controller: controller);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.classData, required this.controller});
  
  final InstituteClass classData;
  final ClassesController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.r20,
        child: InkWell(
          borderRadius: AppRadii.r20,
          onTap: () {
            ClassDetailsView.show(
              context,
              classData: classData,
              controller: controller,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        classData.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                      ),
                    ),
                    if (controller.canEdit)
                      AppActionMenu(
                        actions: [
                          AppActionItem(
                            label: 'Edit Class',
                            icon: Icons.edit_rounded,
                            type: AppActionType.edit,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddEditClassDialog(
                                  controller: controller,
                                  existingClass: classData,
                                ),
                              );
                            },
                          ),
                          if (controller.canDelete)
                            AppActionItem(
                              label: 'Delete Class',
                              icon: Icons.delete_forever_rounded,
                              type: AppActionType.delete,
                              onTap: () async {
                                final confirm = await AppDialogs.showConfirm(
                                  context,
                                  title: 'Delete Class?',
                                  message: 'Are you sure you want to delete ${classData.displayName}? This cannot be undone.',
                                  confirmLabel: 'Delete',
                                  cancelLabel: 'Cancel',
                                  isDanger: true,
                                );
                                if (confirm == true) {
                                  try {
                                    AppDialogs.showLoading(context, message: 'Deleting class...');
                                    await controller.deleteClass(classData.id);
                                    if (context.mounted) {
                                      AppDialogs.hide(context);
                                      AppToasts.showSuccess(context, message: 'Class deleted successfully.');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppDialogs.hide(context);
                                      AppToasts.showError(context, message: e.toString());
                                    }
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                  ],
                ),
                if (!classData.isActive) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cs.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_pin_rounded, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        classData.classTeacherName ?? 'No Class Teacher',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.groups_rounded, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${classData.studentCount} Students',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
