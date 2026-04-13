import 'package:educore/src/app/shell/sidebar.dart';
import 'package:educore/src/app/shell/topbar.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.body, required this.title});

  final Widget body;
  final String title;

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

