import 'package:flutter/material.dart';

import 'navigation_shortcuts.dart';

class FinatiolAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FinatiolAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.includeBackOrHomeLeading = true,
    this.includeHomeAction = true,
    this.homeRoute = '/dashboard',
  });

  final Widget title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final bool includeBackOrHomeLeading;
  final bool includeHomeAction;
  final String homeRoute;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final resolvedActions = <Widget>[];

    if (includeHomeAction) {
      resolvedActions.add(
        NavigationShortcuts.homeAction(context, homeRoute: homeRoute),
      );
    }

    resolvedActions.addAll(actions);

    final showLeading = includeBackOrHomeLeading && (canPop || !includeHomeAction);

    return AppBar(
      leading: showLeading
          ? NavigationShortcuts.backOrHomeLeading(
              context,
              homeRoute: homeRoute,
            )
          : null,
      title: title,
      actions: resolvedActions.isEmpty ? null : resolvedActions,
      bottom: bottom,
    );
  }
}
