// lib/extension/app_extension.dart

import 'package:flutter/material.dart';

extension Routes on BuildContext {
  NavigatorState get route => Navigator.of(this);
  buildRoute(Widget src) {
    return MaterialPageRoute(builder: (context) => src);
  }

  void pushRoute(Widget screen) {
    route.push(buildRoute(screen));
  }

  void popRoute() => route.pop();
}

extension Adaptives on int {
  get ht => SizedBox(height: toDouble());
  get wt => SizedBox(width: toDouble());
}