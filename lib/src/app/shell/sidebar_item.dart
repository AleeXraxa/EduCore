import 'package:flutter/material.dart';

@immutable
class SidebarItemData {
  const SidebarItemData({
    required this.id,
    required this.label,
    required this.icon,
    this.requiredFeature,
  });

  final String id;
  final String label;
  final IconData icon;
  
  /// The feature key required to see/access this item.
  /// If null, it is always visible (system core).
  final String? requiredFeature;
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
