import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Generic badge / pill label
// ──────────────────────────────────────────────────────────────────────────────

/// Generic badge/pill label widget.
///
/// Use the factory constructors for common presets:
/// - `BadgeWidget.item()` / `BadgeWidget.service()` — item type pills
/// - `BadgeWidget.status(label:, status:)` — coloured status pills
/// - `BadgeWidget.active(isActive:)` — Active/Inactive pill (replaces the
///   old `StatusChip` from `shared_ui_elements.dart`)
class BadgeWidget extends StatelessWidget {
  const BadgeWidget({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.width,
    this.pill = false,
  });

  final String label;
  final Color? color;
  final Color? backgroundColor;

  /// Optional fixed width for alignment in tables.
  final double? width;

  /// When true uses a fully-rounded pill shape (for status chips).
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final radius = pill ? AppBorderRadius.full : AppBorderRadius.xs;
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color ?? AppColors.primary,
          fontWeight: FontWeight.w400,
          fontSize: pill ? null : 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
    if (width != null) return SizedBox(width: width, child: badge);
    return badge;
  }

  /// Pill for Item line-item type.
  factory BadgeWidget.item() => BadgeWidget(
        label: 'Item',
        color: AppColors.primary,
        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        width: 62,
      );

  /// Pill for Service line-item type.
  factory BadgeWidget.service() => const BadgeWidget(
        label: 'Service',
        color: Color(0xFF4B5563),
        backgroundColor: Color(0x144B5563),
        width: 62,
      );

  /// Coloured pill driven by [BadgeStatus] severity.
  factory BadgeWidget.status({
    required String label,
    required BadgeStatus status,
  }) {
    final (color, bg) = _statusColors(status);
    return BadgeWidget(label: label, color: color, backgroundColor: bg, pill: true);
  }

  /// Active / Inactive pill — replaces the old `StatusChip` widget.
  factory BadgeWidget.active({required bool isActive}) => BadgeWidget(
        label: isActive ? 'Active' : 'Inactive',
        color: isActive ? AppColors.success : AppColors.textSecondary,
        backgroundColor: isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.textHint.withValues(alpha: 0.2),
        pill: true,
      );

  static (Color, Color) _statusColors(BadgeStatus s) => switch (s) {
        BadgeStatus.success => (
            AppColors.success,
            AppColors.successLight
          ),
        BadgeStatus.warning => (
            AppColors.warning,
            AppColors.warningLight
          ),
        BadgeStatus.error => (
            AppColors.error,
            AppColors.errorLight
          ),
        BadgeStatus.info => (
            AppColors.info,
            AppColors.infoLight
          ),
        BadgeStatus.neutral => (
            AppColors.textSecondary,
            AppColors.surfaceVariant
          ),
      };
}

enum BadgeStatus { success, warning, error, info, neutral }

// ──────────────────────────────────────────────────────────────────────────────
// Stock quantity badge (low-stock aware)
// ──────────────────────────────────────────────────────────────────────────────

/// Coloured quantity pill — red when stock < 10, green otherwise.
class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final isLow = stock < 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Text(
        stock.toString(),
        style: AppTextStyles.caption.copyWith(
          color: isLow ? AppColors.error : AppColors.success,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Row action icon (edit / delete / view)
// ──────────────────────────────────────────────────────────────────────────────

/// Small tappable icon with a tooltip — used in table action columns.
class ActionIcon extends StatelessWidget {
  const ActionIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Confirm-delete dialog
// ──────────────────────────────────────────────────────────────────────────────

/// Shows a standard confirmation dialog before deleting [name].
/// Calls [onConfirm] only if the user presses Delete.
void confirmDeleteDialog(
  BuildContext context, {
  required String name,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Delete "$name"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            onConfirm();
            Navigator.pop(ctx);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
