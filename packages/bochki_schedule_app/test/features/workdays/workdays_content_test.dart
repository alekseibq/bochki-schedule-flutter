import 'package:bochki_schedule_app/src/domain/workdays/workday.dart';
import 'package:bochki_schedule_app/src/features/workdays/workdays_content.dart';
import 'package:bochki_schedule_app/src/features/workdays/workdays_operations.dart';
import 'package:bochki_schedule_app/src/features/workdays/workdays_view_model.dart';
import 'package:bochki_schedule_app/src/features/workdays/workday_form_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _WorkdaysOperations implements WorkdaysOperations {
  List<double> widths = [260, 160, 100, 90];
  bool failCreate = false;
  @override
  Future<List<Workday>> list() async => [];
  @override
  Future<Workday> create(Workday workday) async {
    if (failCreate) throw StateError('offline');
    return workday;
  }

  @override
  Future<Workday> update(Workday workday) async => workday;
  @override
  Future<int> countReferences(String id) async => 0;
  @override
  Future<void> delete(String id) async {}
  @override
  Future<List<double>> loadColumnWidths() async => widths;
  @override
  Future<void> saveColumnWidths(List<double> value) async =>
      widths = List.of(value);
}

void main() {
  testWidgets(
      'restores old widths, resizes adjacent columns, and persists them',
      (tester) async {
    final operations = _WorkdaysOperations();
    final viewModel = WorkdaysViewModel.fromOperations(operations);
    final initial = await viewModel.loadColumnWidths();
    Future<void> pumpContent(List<double> widths) =>
        tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 800,
                  height: 500,
                  child: WorkdaysContent(
                    viewModel: viewModel,
                    columnWidths: widths,
                    onColumnWidthsChanged: viewModel.saveColumnWidths,
                    onOpenCreate: () {},
                    onOpenEdit: (_) {},
                    onOpenReorder: (_) {},
                  ))),
        ));
    await pumpContent(initial);
    final first = find.byKey(const Key('workdays_column_resizer_0'));
    final second = find.byKey(const Key('workdays_column_resizer_1'));
    final oldFirst = tester.getCenter(first).dx;
    final oldSecond = tester.getCenter(second).dx;
    await tester.drag(first, const Offset(30, 0));
    await tester.pump();
    expect(operations.widths, [290, 130, 116, 100, 90]);
    expect(tester.getCenter(first).dx, oldFirst + 30);
    expect(tester.getCenter(second).dx, oldSecond);
    await pumpContent(await viewModel.loadColumnWidths());
    expect(tester.getCenter(first).dx, oldFirst + 30);
    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.dispose();
  });

  testWidgets('shows a failed save inside the standalone workday form',
      (tester) async {
    final operations = _WorkdaysOperations()..failCreate = true;
    final viewModel = WorkdaysViewModel.fromOperations(operations);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WorkdayFormContent(
          viewModel: viewModel,
          initialWorkday: Workday(
            id: 'new',
            name: 'Черновик',
            calendarDate: DateTime(2026, 1, 2),
          ),
          isEditing: false,
          onSaved: (_) {},
          onCancel: () {},
        ),
      ),
    ));

    await tester.enterText(find.byKey(const Key('workday_name_field')), 'День');
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось сохранить изменения.'), findsOneWidget);
    expect(viewModel.actionErrorMessage, isNull);
    viewModel.dispose();
  });
}
