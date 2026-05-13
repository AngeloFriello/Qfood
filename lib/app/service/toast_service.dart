import 'package:dashboard/app/router/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

class ToastService {
  final AppRouter appRouter;

  ToastService({required this.appRouter});

  void showToast({
    required Widget title,
    Widget? description,
    ToastificationType type = ToastificationType.success,
    ToastificationStyle style = ToastificationStyle.fillColored,
    Alignment alignment = Alignment.bottomCenter,
    Duration autoCloseDuration = const Duration(seconds: 5),
    bool showProgressBar = true,
bool applyBlurEffect = false,
  }) {
    toastification.show(
        overlayState: appRouter.navigatorKey.currentState!.overlay,
        type: type,
        style: style,
        title: title,
        description: description,
        alignment: alignment,
        autoCloseDuration: autoCloseDuration,
        showProgressBar: showProgressBar,
        applyBlurEffect: applyBlurEffect
        );
  }

  void showCustomToast({
    required Widget Function(BuildContext, ToastificationItem) child,
    Duration autoCloseDuration = const Duration(seconds: 5),
  }) {
    toastification.showCustom(
      overlayState: appRouter.navigatorKey.currentState!.overlay,
      autoCloseDuration: autoCloseDuration,
      builder: child,
    );
  }
}
