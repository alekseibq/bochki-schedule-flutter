import 'package:bochki_schedule_app/src/domain/procedure_sessions/procedure_session_tooltip_builder.dart';
import 'package:bochki_schedule_app/src/presentation/app_tooltips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines the shared light tooltip visual standard', () {
    expect(AppTooltips.theme.decoration, isA<BoxDecoration>());
    final decoration = AppTooltips.theme.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFCFCFD));
    expect(decoration.border, Border.all(color: const Color(0xFFD0D5DD)));
    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect(decoration.boxShadow, isNull);
    expect(
      AppTooltips.theme.padding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    expect(AppTooltips.theme.textStyle?.color, const Color(0xFF1D2939));
  });

  test('maps every rich tooltip text category independently from boldness', () {
    final styles = [
      AppTooltips.textStyle(const ProcedureSessionTooltipText('Обычный')),
      AppTooltips.textStyle(const ProcedureSessionTooltipText(
        'Конфликт',
        category: ProcedureSessionTooltipTextCategory.conflict,
        isBold: true,
      )),
      AppTooltips.textStyle(const ProcedureSessionTooltipText(
        'Акцент',
        category: ProcedureSessionTooltipTextCategory.accent,
      )),
    ];

    expect(styles[0].color, const Color(0xFF1D2939));
    expect(styles[0].fontWeight, isNull);
    expect(styles[1].color, const Color(0xFFB42318));
    expect(styles[1].fontWeight, FontWeight.bold);
    expect(styles[2].color, const Color(0xFF166534));
    expect(styles[2].fontWeight, isNull);
  });
}
