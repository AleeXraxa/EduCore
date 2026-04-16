import 'package:educore/src/app/shell/sidebar.dart';
import 'package:educore/src/app/shell/sidebar_item.dart';
import 'package:educore/src/app/shell/topbar.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.title,
    this.sections = const [],
    this.selectedSidebarId,
    this.onSelectSidebar,
    this.bottomItems = const [],
  });

  final Widget body;
  final String title;
  final List<SidebarSectionData> sections;
  final String? selectedSidebarId;
  final ValueChanged<String>? onSelectSidebar;
  final List<SidebarItemData> bottomItems;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = screenSizeForWidth(constraints.maxWidth);
        
        // Auto-collapse logic:
        // Expanded (Desktop) -> User preference (default expanded)
        // Medium (Tablet/Small Laptop) -> Forced Rail (collapsed)
        // Compact (Mobile) -> Forced Rail or Drawer (for now, Forced Rail)
        final isNarrow = screen != ScreenSize.expanded;
        final effectiveCollapsed = isNarrow || _collapsed;

        return Scaffold(
          body: Row(
            children: [
              Sidebar(
                collapsed: effectiveCollapsed,
                onToggle: () => setState(() => _collapsed = !_collapsed),
                sections: widget.sections,
                selectedId: widget.selectedSidebarId,
                onSelect: widget.onSelectSidebar,
                bottomItems: widget.bottomItems,
              ),
              Expanded(
                child: Column(
                  children: [
                    Topbar(
                      title: widget.title,
                      onToggleSidebar: () =>
                          setState(() => _collapsed = !_collapsed),
                    ),
                    Expanded(child: widget.body),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
