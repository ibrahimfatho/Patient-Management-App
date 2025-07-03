import 'package:flutter/material.dart';
import '../utils/theme.dart';

class EnhancedListView extends StatelessWidget {
  final List<Widget> children;
  final Widget? emptyStateWidget;
  final Widget? loadingWidget;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isLoading;
  final EdgeInsetsGeometry padding;
  final Widget? header;
  final Widget? footer;
  final bool showShadow;
  final Color backgroundColor;
  final double itemSpacing;
  final ScrollController? scrollController;

  const EnhancedListView({
    super.key,
    required this.children,
    this.emptyStateWidget,
    this.loadingWidget,
    this.errorMessage,
    this.onRetry,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    this.header,
    this.footer,
    this.showShadow = true,
    this.backgroundColor = const Color(0xFFF9F9F9),
    this.itemSpacing = 16,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryColor,
            ),
          );
    }

    if (children.isEmpty) {
      return emptyStateWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: Colors.grey.shade400,
                  size: 72,
                ),
                const SizedBox(height: 20),
                Text(
                  'لا توجد عناصر للعرض',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 19,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
    }

    return Container(
      color: backgroundColor,
      child: ListView.separated(
        controller: scrollController,
        padding: padding,
        itemCount:
            children.length +
            (header != null ? 1 : 0) +
            (footer != null ? 1 : 0),
        separatorBuilder: (context, index) {
          final isLast =
              index == children.length + (header != null ? 1 : 0) - 1;
          if (header != null && index == 0) return const SizedBox.shrink();
          if (footer != null && isLast) return const SizedBox.shrink();
          return SizedBox(height: itemSpacing);
        },
        itemBuilder: (context, index) {
          // Header
          if (header != null && index == 0) {
            return header!;
          }

          // Footer
          if (footer != null &&
              index == children.length + (header != null ? 1 : 0)) {
            return footer!;
          }

          // List items
          final itemIndex = index - (header != null ? 1 : 0);
          if (itemIndex >= 0 && itemIndex < children.length) {
            return children[itemIndex];
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class EnhancedListItem extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget>? chips;
  final List<Widget>? details;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry contentPadding;
  final Color? backgroundColor;
  final double borderRadius;
  final Widget? expandedContent;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const EnhancedListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.chips,
    this.details,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    this.backgroundColor,
    this.borderRadius = 16,
    this.expandedContent,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with leading, title/subtitle, and trailing
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Leading widget (icon, avatar, etc)
                    Container(
                      margin: const EdgeInsets.only(right: 2, top: 2, left: 12),
                      child: leading,
                    ),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle(
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                            child: title,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            DefaultTextStyle(
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(color: Colors.grey.shade500),
                              child: subtitle!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Trailing (menu, icon, etc)
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
                // Optional divider

                // Details section (bottom row)
                if (details != null && details!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: details!,
                  ),
                ],
                // Chips section
                if (chips != null && chips!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, runSpacing: 8, children: chips!),
                ],
                // Expandable section
                if (expandedContent != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: InkWell(
                      onTap: onToggleExpand,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState:
                        isExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: expandedContent!,
                    ),
                    secondChild: const SizedBox.shrink(),
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

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailItem extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color? iconColor;
  final TextStyle? textStyle;

  const DetailItem({
    super.key,
    this.icon,
    required this.text,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style:
              textStyle ??
              Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
