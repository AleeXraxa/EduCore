import 'package:educore/src/app/shell/sidebar.dart';
import 'package:educore/src/app/shell/sidebar_item.dart';
import 'package:educore/src/app/shell/topbar.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.title,
    this.sidebarItems = const [],
    this.selectedSidebarId,
    this.onSelectSidebar,
    this.bottomItems = const [],
  });

  final Widget body;
  final String title;
  final List<SidebarItemData> sidebarItems;
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
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            collapsed: _collapsed,
            onToggle: () => setState(() => _collapsed = !_collapsed),
            items: widget.sidebarItems,
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
  }
}
