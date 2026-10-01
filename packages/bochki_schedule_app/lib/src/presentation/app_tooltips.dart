import 'package:flutter/material.dart';

import '../domain/procedure_sessions/procedure_session_tooltip_builder.dart';

/// Visual tokens shared by every tooltip shown by the application.
abstract final class AppTooltips {
  static const TooltipThemeData theme = TooltipThemeData(
    decoration: BoxDecoration(
      color: Color(0xFFFCFCFD),
      borderRadius: BorderRadius.all(Radius.circular(8)),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFFD0D5DD))),
    ),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    textStyle: TextStyle(color: Color(0xFF1D2939)),
  );

  static TextStyle textStyle(ProcedureSessionTooltipText text) => TextStyle(
        color: switch (text.category) {
          ProcedureSessionTooltipTextCategory.normal => const Color(0xFF1D2939),
          ProcedureSessionTooltipTextCategory.conflict =>
            const Color(0xFFB42318),
          ProcedureSessionTooltipTextCategory.accent => const Color(0xFF166534),
        },
        fontWeight: text.isBold ? FontWeight.bold : null,
      );
}
