import 'package:flutter/material.dart';

@immutable
class SidebarItemData {
  const SidebarItemData({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

@immutable
class SidebarSectionData {
  const SidebarSectionData({
    required this.title,
    required this.items,
  });

  final String title;
  final List<SidebarItemData> items;
}
