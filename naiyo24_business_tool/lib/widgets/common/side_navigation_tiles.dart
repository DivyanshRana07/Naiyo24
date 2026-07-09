import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

class DropdownGroupTile extends StatefulWidget {
  const DropdownGroupTile({
    super.key,
    required this.isExpanded,
    required this.isActive,
    required this.isOpen,
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final bool isExpanded;
  final bool isActive;
  final bool isOpen;
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  State<DropdownGroupTile> createState() => _DropdownGroupTileState();
}

class _DropdownGroupTileState extends State<DropdownGroupTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color iconColor = AppColors.textSecondary;
    Color textColor = AppColors.textSecondary;

    if (widget.isActive && !_isHovered) {
      bgColor = AppColors.primary.withValues(alpha: 0.08);
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    if (_isHovered) {
      bgColor = AppColors.primary;
      iconColor = AppColors.textOnPrimary;
      textColor = AppColors.textOnPrimary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? AppSpacing.sm : 4.0,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: (widget.isActive && !_isHovered)
              ? Border(
                  left: BorderSide(color: AppColors.primary, width: 4))
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded ? AppSpacing.md : 0,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: widget.isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: iconColor,
                ),
                if (widget.isExpanded) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight:
                            widget.isActive ? FontWeight.w400 : FontWeight.w400,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: widget.isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: textColor,
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

class DropdownChildTile extends StatefulWidget {
  const DropdownChildTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<DropdownChildTile> createState() => _DropdownChildTileState();
}

class _DropdownChildTileState extends State<DropdownChildTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color iconColor = AppColors.textSecondary;
    Color textColor = AppColors.textSecondary;

    if (widget.selected && !_isHovered) {
      bgColor = AppColors.primary.withValues(alpha: 0.10);
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    if (_isHovered) {
      bgColor = AppColors.primary.withValues(alpha: 0.06);
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(left: 28, right: 8, top: 1, bottom: 1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 14,
                  decoration: BoxDecoration(
                    color:
                        widget.selected ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(widget.item.icon, size: 16, color: iconColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight:
                          widget.selected ? FontWeight.w400 : FontWeight.w400,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavTile extends StatefulWidget {
  const NavTile({
    super.key,
    required this.item,
    required this.selected,
    required this.isExpanded,
    required this.onTap,
    this.isErrorColor = false,
  });

  final NavItem item;
  final bool selected;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isErrorColor;

  @override
  State<NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<NavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isErrorColor ? AppColors.error : AppColors.primary;

    Color bgColor = Colors.transparent;
    Color iconColor = AppColors.textSecondary;
    Color textColor = AppColors.textSecondary;

    if (widget.selected && !_isHovered) {
      bgColor = activeColor.withValues(alpha: 0.12);
      iconColor = activeColor;
      textColor = activeColor;
    }

    if (_isHovered) {
      bgColor = widget.isErrorColor ? AppColors.error : AppColors.primary;
      iconColor = AppColors.textOnPrimary;
      textColor = AppColors.textOnPrimary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? AppSpacing.sm : 4.0,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: (widget.selected && !_isHovered)
              ? Border(left: BorderSide(color: activeColor, width: 4))
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded ? AppSpacing.md : 0,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: widget.isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.item.icon, size: 20, color: iconColor),
                if (widget.isExpanded) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight:
                            widget.selected ? FontWeight.w400 : FontWeight.w400,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
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
