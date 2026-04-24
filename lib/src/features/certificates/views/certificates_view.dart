import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_table.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/certificates/controllers/certificate_controller.dart';
import 'package:educore/src/features/certificates/models/certificate.dart';
import 'package:educore/src/features/certificates/views/certificate_form_dialog.dart';
import 'package:educore/src/features/certificates/views/certificate_templates_view.dart';
import 'package:educore/src/features/certificates/widgets/certificate_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class CertificatesView extends StatefulWidget {
  const CertificatesView({super.key});

  @override
  State<CertificatesView> createState() => _CertificatesViewState();
}

class _CertificatesViewState extends State<CertificatesView>
    with SingleTickerProviderStateMixin {
  late final CertificateController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = CertificateController();
    _tabController = TabController(length: 2, vsync: this);
    final academyId = AppServices.instance.authService?.currentAcademyId;
    if (academyId != null) {
      _controller.init(academyId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showGenerateDialog(BuildContext context, {Certificate? certificate}) {
    showDialog(
      context: context,
      builder: (_) => CertificateFormDialog(certificate: certificate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Certificates & Documents',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'Generated Certificates'),
                  Tab(text: 'Design Templates'),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildMainDashboard(), const CertificateTemplatesView()],
          ),
        ),
      ],
    );
  }

  Widget _buildMainDashboard() {
    return ControllerBuilder<CertificateController>(
      controller: _controller,
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final isMobile = size == ScreenSize.compact;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildKpis(context, controller, size),
                  const SizedBox(height: 32),
                  _buildFilters(context, controller, isMobile),
                  const SizedBox(height: 24),
                  _buildCertificateTable(context, controller, isMobile),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canCreate =
        AppServices.instance.featureAccessService?.canAccess(
          'certificate_create',
        ) ??
        false;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Certificates',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'View and manage issued student documents',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (canCreate)
          AppButton(
            label: 'Generate New',
            icon: Icons.add_rounded,
            onPressed: () => _showGenerateDialog(context),
            variant: AppButtonVariant.primary,
          ),
      ],
    );
  }

  Widget _buildKpis(
    BuildContext context,
    CertificateController controller,
    ScreenSize size,
  ) {
    final columns = size == ScreenSize.compact
        ? 1
        : (size == ScreenSize.medium ? 2 : 4);

    return AppAnimatedSlide(
      delayIndex: 1,
      child: AppKpiGrid(
        columns: columns,
        items: [
          KpiCardData(
            label: 'Total Certificates',
            value: controller.totalCertificates.toString(),
            icon: Icons.workspace_premium_rounded,
            gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
          ),
          KpiCardData(
            label: 'Generated This Month',
            value: controller.generatedThisMonth.toString(),
            icon: Icons.calendar_today_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
          ),
          KpiCardData(
            label: 'Downloaded Count',
            value: controller.totalDownloads.toString(),
            icon: Icons.file_download_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          KpiCardData(
            label: 'Templates',
            value: controller.activeTemplates.toString(),
            icon: Icons.dashboard_customize_rounded,
            gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    CertificateController controller,
    bool isMobile,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: controller.setSearch,
              decoration: InputDecoration(
                hintText: 'Search student name or ID...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildTypeFilter(context, controller),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(
    BuildContext context,
    CertificateController controller,
  ) {
    return PopupMenuButton<CertificateType?>(
      onSelected: controller.setTypeFilter,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('All Types')),
        ...CertificateType.values.map(
          (t) => PopupMenuItem(value: t, child: Text(t.label)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.filter_list_rounded, size: 20),
            SizedBox(width: 8),
            Text('Filter Type'),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateTable(
    BuildContext context,
    CertificateController controller,
    bool isMobile,
  ) {
    if (controller.busy) {
      return const _LoadingSkeleton();
    }

    if (controller.certificates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text('No certificates found.'),
            ],
          ),
        ),
      );
    }

    return AppTable<Certificate>(
      items: controller.certificates,
      columns: [
        AppTableColumn(
          label: 'Certificate ID',
          flex: 1,
          builder: (c) => Text(
            c.id.substring(0, 8).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        AppTableColumn(
          label: 'Student Name',
          flex: 2,
          builder: (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.studentName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (c.className != null)
                Text(
                  c.className!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        AppTableColumn(
          label: 'Type',
          flex: 1,
          builder: (c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              c.type.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
        AppTableColumn(
          label: 'Issue Date',
          flex: 1,
          builder: (c) => Text(DateFormat('dd MMM yyyy').format(c.issueDate)),
        ),
        AppTableColumn(
          label: 'Downloads',
          flex: 1,
          builder: (c) => Row(
            children: [
              const Icon(
                Icons.download_done_rounded,
                size: 14,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(c.downloadCount.toString()),
            ],
          ),
        ),
        AppTableColumn(
          label: 'Actions',
          width: 80,
          builder: (c) => _buildActions(context, c),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Certificate cert) {
    final featureSvc = AppServices.instance.featureAccessService;
    final canEdit = featureSvc?.canAccess('certificate_create') ?? false;
    final canDelete = featureSvc?.canAccess('certificate_create') ?? false;
    final canDownload = featureSvc?.canAccess('certificate_download') ?? true;

    return AppActionMenu(
      actions: [
        AppActionItem(
          label: 'View / Preview',
          icon: Icons.visibility_rounded,
          onTap: () => _handleDownload(context, cert, preview: true),
        ),
        if (canDownload)
          AppActionItem(
            label: 'Download PDF',
            icon: Icons.download_rounded,
            onTap: () => _handleDownload(context, cert),
          ),
        if (canDownload)
          AppActionItem(
            label: 'Print',
            icon: Icons.print_rounded,
            onTap: () => _handlePrint(context, cert),
          ),
        if (canEdit)
          AppActionItem(
            label: 'Edit',
            icon: Icons.edit_rounded,
            onTap: () => _showGenerateDialog(context, certificate: cert),
          ),
        if (canDelete)
          AppActionItem(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            type: AppActionType.delete,
            onTap: () => _handleDelete(context, cert),
          ),
      ],
    );
  }

  Future<void> _handleDownload(
    BuildContext context,
    Certificate cert, {
    bool preview = false,
  }) async {
    final academyId = AppServices.instance.authService?.currentAcademyId;
    if (academyId == null) return;

    final instituteName =
        AppServices.instance.authService?.currentAcademyName ?? 'Institute';
    final logoUrl = AppServices.instance.authService?.currentAcademyLogo;

    if (!preview) {
      await _controller.logDownload(academyId, cert);
    }

    await CertificatePdfGenerator.download(
      cert,
      instituteName,
      instituteLogoUrl: logoUrl,
      backgroundUrl: cert.templateBackgroundUrl,
    );
  }

  Future<void> _handlePrint(BuildContext context, Certificate cert) async {
    final instituteName =
        AppServices.instance.authService?.currentAcademyName ?? 'Institute';
    final logoUrl = AppServices.instance.authService?.currentAcademyLogo;
    await CertificatePdfGenerator.printPdf(
      cert,
      instituteName,
      instituteLogoUrl: logoUrl,
      backgroundUrl: cert.templateBackgroundUrl,
    );
  }

  Future<void> _handleDelete(BuildContext context, Certificate cert) async {
    final academyId = AppServices.instance.authService?.currentAcademyId;
    if (academyId == null) return;

    final confirmed = await AppDialogs.showConfirm(
      context,
      title: 'Delete Certificate?',
      message:
          'This will permanently remove the certificate record for ${cert.studentName}. PDF files already downloaded will remain valid.',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (!mounted || confirmed != true) return;

    await _controller.deleteCertificate(academyId, cert);
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: SpinKitFadingCube(color: Colors.blue, size: 40));
  }
}
