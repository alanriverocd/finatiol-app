import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationShortcuts {
  const NavigationShortcuts._();

  static void goBackOrHome(BuildContext context, {String homeRoute = '/dashboard'}) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(homeRoute);
  }

  static Widget backOrHomeLeading(BuildContext context, {String homeRoute = '/dashboard'}) {
    final canPop = Navigator.of(context).canPop();
    return IconButton(
      tooltip: canPop ? 'Volver' : 'Ir a inicio',
      icon: Icon(canPop ? Icons.arrow_back : Icons.home_outlined),
      onPressed: () => goBackOrHome(context, homeRoute: homeRoute),
    );
  }

  static IconButton homeAction(BuildContext context, {String homeRoute = '/dashboard'}) {
    return IconButton(
      tooltip: 'Inicio',
      icon: const Icon(Icons.home_outlined),
      onPressed: () => context.go(homeRoute),
    );
  }
}
