import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class Sidebar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isAdvancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: widget.isCollapsed ? 70 : 250,
      decoration: BoxDecoration(
        color: theme.glassBg,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWidening = constraints.maxWidth > 100;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              if (isWidening) _buildSectionHeader(theme, 'SESSIONS'),
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                selected: widget.currentIndex == 0,
                onTap: () => widget.onIndexChanged(0),
                isCollapsed: !isWidening,
              ),

              const SizedBox(height: 16),
              if (isWidening) _buildSectionHeader(theme, 'DEVICE'),
              _NavItem(
                icon: Icons.apps_rounded,
                label: 'Apps',
                selected: widget.currentIndex == 1,
                onTap: () => widget.onIndexChanged(1),
                isCollapsed: !isWidening,
              ),
              _NavItem(
                icon: Icons.phonelink_setup_rounded,
                label: 'Media Control',
                selected: widget.currentIndex == 7,
                onTap: () => widget.onIndexChanged(7),
                isCollapsed: !isWidening,
              ),
              _NavItem(
                icon: Icons.cast_connected_rounded,
                label: 'Mirroring',
                selected: widget.currentIndex == 2,
                onTap: () => widget.onIndexChanged(2),
                isCollapsed: !isWidening,
              ),
              _NavItem(
                icon: Icons.videocam_rounded,
                label: 'Virtual Webcam',
                selected: widget.currentIndex == 3,
                onTap: () => widget.onIndexChanged(3),
                isCollapsed: !isWidening,
              ),

              const SizedBox(height: 16),
              if (isWidening) _buildSectionHeader(theme, 'MANAGEMENT'),
              _NavItem(
                icon: Icons.folder_rounded,
                label: 'Files',
                selected: widget.currentIndex == 4,
                onTap: () => widget.onIndexChanged(4),
                isCollapsed: !isWidening,
              ),

              // Advanced Group
              _ExpandableNavItem(
                icon: Icons.terminal_rounded,
                label: 'Advanced',
                isExpanded: _isAdvancedExpanded,
                onToggle: () =>
                    setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
                isCollapsed: !isWidening,
                isSelected: [8, 9, 10].contains(widget.currentIndex),
                children: [
                  _SubNavItem(
                    label: 'ADB Shell',
                    selected: widget.currentIndex == 8,
                    onTap: () => widget.onIndexChanged(8),
                  ),
                  _SubNavItem(
                    label: 'Fastboot',
                    selected: widget.currentIndex == 9,
                    onTap: () => widget.onIndexChanged(9),
                  ),
                  _SubNavItem(
                    label: 'ADB Logs',
                    selected: widget.currentIndex == 10,
                    onTap: () => widget.onIndexChanged(10),
                  ),
                ],
              ),

              const Spacer(),
              _NavItem(
                icon: Icons.info_rounded,
                label: 'About',
                selected: widget.currentIndex == 6,
                onTap: () => widget.onIndexChanged(6),
                isCollapsed: !isWidening,
              ),

              if (isWidening) ...[
                const Divider(height: 1, color: Colors.white10),
              ],
              if (!isWidening) const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(dynamic theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.textMuted.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isCollapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: isCollapsed ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: selected ? theme.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : theme.textMuted,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? Colors.white : theme.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isCollapsed;
  final bool isSelected;
  final List<Widget> children;

  const _ExpandableNavItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onToggle,
    required this.isCollapsed,
    required this.isSelected,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    // If collapsed, act like a normal item but maybe show a tooltip or popover in future
    // For now, if collapsed, we can't really expand details easily without an overlay.
    // Let's just make clicking it toggle expansion/selection visualization if we were to support it.
    // But since sub-items are text based, in collapsed mode they should probably be hidden or standard icons.
    // For simplicity: if collapsed, we just show the parent icon. Clicking it might not do much or could expand sidebar.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: GestureDetector(
            onTap: onToggle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: isCollapsed ? 0 : 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected && isCollapsed
                      ? theme.accentPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? (isCollapsed ? Colors.white : theme.accentPrimary)
                          : theme.textMuted,
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.accentPrimary
                                : theme.textMuted,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        size: 16,
                        color: theme.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded && !isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 28), // Indent sub-items
            child: Column(children: children),
          ),
      ],
    );
  }
}

class _SubNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: selected
                  ? theme.accentPrimary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? theme.accentPrimary : theme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
