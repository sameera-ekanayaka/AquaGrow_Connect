import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// One tab of [PillNavBar].
class PillNavItem {
  /// Creates a tab with an [icon], a filled [selectedIcon] and a [label].
  const PillNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Icon while the tab is not selected.
  final IconData icon;

  /// Icon while the tab is selected.
  final IconData selectedIcon;

  /// Tab name, shown next to the icon when selected and read by screen readers.
  final String label;
}

/// The Minimal UI tab bar: a floating white pill where the current tab is a
/// lime pill with its icon and label side by side, and the others show only
/// their icon.
class PillNavBar extends StatelessWidget {
  /// Creates the bar for [items], with [selectedIndex] highlighted.
  const PillNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// The tabs, in order.
  final List<PillNavItem> items;

  /// Index of the current tab.
  final int selectedIndex;

  /// Called with the index of the tapped tab.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AgSpace.s16,
          0,
          AgSpace.s16,
          AgSpace.s8,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: AgRadius.all(AgRadius.pill),
            boxShadow: [
              BoxShadow(
                color: c.text.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AgSpace.s8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < items.length; i++)
                  _Tab(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: selected ? c.brand : Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: kMinTouchTarget,
                  minHeight: kMinTouchTarget,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? AgSpace.s20 : AgSpace.s12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: selected ? c.text : c.textSecondary,
                      ),
                      if (selected) ...[
                        const SizedBox(width: AgSpace.s8),
                        Text(item.label, style: text.labelLarge),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
