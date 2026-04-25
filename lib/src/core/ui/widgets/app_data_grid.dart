import 'dart:ui';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppDataGridColumn {
  const AppDataGridColumn({
    required this.label,
    this.width,
    this.flex = 1,
    this.center = false,
  });

  final String label;
  final double? width;
  final int flex;
  final bool center;
}

class AppDataGrid<T> extends StatefulWidget {
  const AppDataGrid({
    super.key,
    required this.columns,
    required this.items,
    required this.rowBuilder,
    this.onSelectionChanged,
    this.actions = const [],
    this.headerHeight = 56.0,
    this.rowHeight = 72.0,
    this.onRowTap,
  });

  final List<AppDataGridColumn> columns;
  final List<T> items;
  final List<Widget> Function(BuildContext context, T item) rowBuilder;
  final void Function(List<T> selectedItems)? onSelectionChanged;
  final List<Widget> actions;
  final double headerHeight;
  final double rowHeight;
  final void Function(T item)? onRowTap;

  @override
  State<AppDataGrid<T>> createState() => _AppDataGridState<T>();
}

class _AppDataGridState<T> extends State<AppDataGrid<T>> {
  final Set<T> _selectedItems = {};
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  void _toggleSelectAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedItems.addAll(widget.items);
      } else {
        _selectedItems.clear();
      }
    });
    widget.onSelectionChanged?.call(_selectedItems.toList());
  }

  void _toggleSelectItem(T item, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
    widget.onSelectionChanged?.call(_selectedItems.toList());
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            // Header
            _buildHeader(cs),
            // Body
            Expanded(
              child: _buildBody(cs),
            ),
          ],
        ),
        // Frosted Glass Multi-Select Bar
        if (_selectedItems.isNotEmpty)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _buildSelectionBar(cs),
          ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      height: widget.headerHeight,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          if (widget.onSelectionChanged != null)
            SizedBox(
              width: 60,
              child: Checkbox(
                value: _selectedItems.length == widget.items.length && widget.items.isNotEmpty,
                onChanged: _toggleSelectAll,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ...widget.columns.map((col) => _buildHeaderCell(col, cs)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(AppDataGridColumn col, ColorScheme cs) {
    final cell = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: col.center ? Alignment.center : Alignment.centerLeft,
      child: Text(
        col.label.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1.0,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );

    if (col.width != null) {
      return SizedBox(width: col.width, child: cell);
    }
    return Expanded(flex: col.flex, child: cell);
  }

  Widget _buildBody(ColorScheme cs) {
    return ListView.builder(
      controller: _verticalController,
      itemCount: widget.items.length,
      itemExtent: widget.rowHeight,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = _selectedItems.contains(item);

        return _AppDataGridRow(
          isSelected: isSelected,
          onSelectChanged: widget.onSelectionChanged != null 
              ? (val) => _toggleSelectItem(item, val)
              : null,
          onTap: () => widget.onRowTap?.call(item),
          cells: widget.rowBuilder(context, item),
          columns: widget.columns,
        );
      },
    );
  }

  Widget _buildSelectionBar(ColorScheme cs) {
    return Center(
      child: ClipRRect(
        borderRadius: AppRadii.r24,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.9),
              borderRadius: AppRadii.r24,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedItems.length} items selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white24,
                ),
                const SizedBox(width: 12),
                ...widget.actions,
                IconButton(
                  onPressed: () => setState(() => _selectedItems.clear()),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: 'Clear Selection',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDataGridRow extends StatefulWidget {
  const _AppDataGridRow({
    required this.isSelected,
    this.onSelectChanged,
    required this.onTap,
    required this.cells,
    required this.columns,
  });

  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback onTap;
  final List<Widget> cells;
  final List<AppDataGridColumn> columns;

  @override
  State<_AppDataGridRow> createState() => _AppDataGridRowState();
}

class _AppDataGridRowState extends State<_AppDataGridRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? cs.primary.withValues(alpha: 0.05)
                : (_isHovered ? cs.surfaceContainerHighest.withValues(alpha: 0.1) : Colors.transparent),
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              if (widget.onSelectChanged != null)
                SizedBox(
                  width: 60,
                  child: Checkbox(
                    value: widget.isSelected,
                    onChanged: widget.onSelectChanged,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ...List.generate(widget.cells.length, (index) {
                final cell = widget.cells[index];
                final col = widget.columns[index];

                final content = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: col.center ? Alignment.center : Alignment.centerLeft,
                  child: cell,
                );

                if (col.width != null) {
                  return SizedBox(width: col.width, child: content);
                }
                return Expanded(flex: col.flex, child: content);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
