import 'package:flutter/material.dart';

/// Show a Material side sheet.
class DiveSideSheet {
  static showSideSheet({
    required BuildContext context,
    Widget Function(BuildContext)? builder,
    bool rightSide = true,
    Duration animationDuration = const Duration(milliseconds: 300),
    double width = 300,
  }) {
    showGeneralDialog(
      barrierLabel: "dive_side_sheet",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: animationDuration,
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return Align(
          alignment: (rightSide ? Alignment.centerRight : Alignment.centerLeft),
          child: Container(
            child: builder!(context),
            height: double.infinity,
            width: width,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return SlideTransition(
          position:
              Tween(begin: Offset((rightSide ? 1 : -1), 0), end: Offset(0, 0))
                  .animate(animation1),
          child: child,
        );
      },
    );
  }
}
