import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared list content displays curated times and blocks delete',
      (tester) async {
    final operations = _Operations(
      kinds: [
        ProcedureKind(
          id: 'kind-1',
          patternId: 'curated',
          name: 'Бочка',
          capacity: 2,
          participantBusyTime: 30,
          assistantBusyTime: 10,
          resourceBusyTime: 15,
        ),
      ],
      references: 1,
    );
    final viewModel = ProcedureKindsViewModel(operations: operations);
    await viewModel.loadProcedureKinds();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(body: ProcedureKindsContent(viewModel: viewModel)),
    ));
    expect(find.text('10'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    await tester.tap(find.byKey(const Key('procedure_kind_delete_kind-1')));
    await tester.pumpAndSettle();
    expect(find.text('Невозможно удалить процедуру'), findsOneWidget);
    expect(operations.deletedIds, isEmpty);
  });

  testWidgets('shared form content shows curated fields', (tester) async {
    final operations = _Operations();
    final viewModel = ProcedureKindsViewModel(operations: operations);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(
        body: ProcedureKindFormContent(
          viewModel: viewModel,
          procedureKinds: const [],
        ),
      ),
    ));

    expect(find.byKey(const Key('procedure_kind_assistant_busy_time_field')),
        findsOneWidget);
    expect(find.byKey(const Key('procedure_kind_resource_busy_time_field')),
        findsOneWidget);
  });
}

final class _Operations implements ProcedureKindsOperations {
  _Operations({List<ProcedureKind>? kinds, this.references = 0})
      : _kinds = [...?kinds];

  final List<ProcedureKind> _kinds;
  final int references;
  final List<String> deletedIds = [];

  @override
  Future<int> countReferences(String procedureKindId) async => references;

  @override
  Future<ProcedureKind> create(ProcedureKind procedureKind) async =>
      procedureKind;

  @override
  Future<void> delete(String procedureKindId) async =>
      deletedIds.add(procedureKindId);

  @override
  Future<List<ProcedureKind>> list() async => _kinds;

  @override
  Future<ProcedureKind> update(ProcedureKind procedureKind) async =>
      procedureKind;
}
