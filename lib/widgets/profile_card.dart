import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A reusable card component for profile sections
class ProfileCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ProfileCard({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: iconColor ?? theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.foreground,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            color: theme.colorScheme.border,
          ),
          // Content
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A selectable chip/button for profile options
class SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final bool showCheckmark;

  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
    this.showCheckmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = selectedColor ?? theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.15)
              : theme.colorScheme.muted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? color
                : theme.colorScheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && showCheckmark) ...[
              Icon(
                LucideIcons.check,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? color
                    : theme.colorScheme.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A removable tag/badge for user-added items
class RemovableTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Color? color;

  const RemovableTag({
    super.key,
    required this.label,
    required this.onRemove,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final tagColor = color ?? theme.colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: tagColor,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 10,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
