import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared list content displays curated times and blocks delete',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
      home: Scaffold(
        body: ProcedureKindsContent(
          viewModel: viewModel,
        ),
      ),
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
        findsNothing);
    await tester.tap(
      find.byKey(const Key('procedure_kind_use_capacity_restriction_field')),
    );
    await tester.pump();
    expect(find.byKey(const Key('procedure_kind_resource_busy_time_field')),
        findsOneWidget);
  });

  testWidgets('shared list resizes and restores all columns', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final viewModel = ProcedureKindsViewModel(operations: _Operations());
    var savedWidths = const <double>[];

    Future<void> saveWidths(List<double> widths) async {
      savedWidths = widths;
    }

    Widget buildContent() => MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: ProcedureKindsContent(
              viewModel: viewModel,
              columnWidths: savedWidths,
              onColumnWidthsChanged: saveWidths,
            ),
          ),
        );

    await tester.pumpWidget(buildContent());

    final selectorHeader = find.byKey(
      const Key('procedure_kinds_column_header_0'),
    );
    final nameHeader = find.byKey(
      const Key('procedure_kinds_column_header_1'),
    );
    final resizer = find.byKey(
      const Key('procedure_kinds_column_resizer_0'),
    );

    expect(tester.getSize(selectorHeader).width, 36);
    expect(tester.getSize(nameHeader).width, 140);
    for (var index = 0; index < 9; index++) {
      expect(find.byKey(Key('procedure_kinds_column_resizer_$index')),
          findsOneWidget);
    }

    await tester.drag(resizer, const Offset(20, 0));
    await tester.pumpAndSettle();

    expect(tester.getSize(selectorHeader).width, 56);
    expect(tester.getSize(nameHeader).width, 120);
    expect(savedWidths, hasLength(9));

    await tester.pumpWidget(buildContent());
    await tester.pumpAndSettle();

    expect(tester.getSize(selectorHeader).width, 56);
    expect(tester.getSize(nameHeader).width, 120);
  });

  testWidgets('shared form places pair count after assistant time', (
    tester,
  ) async {
    final viewModel = ProcedureKindsViewModel(operations: _Operations());

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(
        body: ProcedureKindFormContent(
          viewModel: viewModel,
          procedureKinds: const [],
        ),
      ),
    ));

    final assistantTime = find.text('Время сопровождающего (мин)');
    final pairCount = find.text('Учитывать в количестве сопровождений');
    final checkbox = find.byKey(
      const Key('procedure_kind_use_for_pair_count'),
    );
    final assistantField = find.byKey(
      const Key('procedure_kind_assistant_busy_time_field'),
    );

    expect(
      tester.getTopLeft(pairCount).dy,
      greaterThan(tester.getTopLeft(assistantTime).dy),
    );
    expect(
        tester.getTopLeft(checkbox).dx, tester.getTopLeft(assistantField).dx);
  });

  testWidgets('shared form shows validation error above actions',
      (tester) async {
    final viewModel = ProcedureKindsViewModel(operations: _Operations());

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(
        body: ProcedureKindFormContent(
          viewModel: viewModel,
          procedureKinds: const [],
        ),
      ),
    ));
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    final error = find.text('Укажите время участника.');
    expect(error, findsOneWidget);
    expect(
      tester.widget<Text>(error).style?.color,
      Theme.of(tester.element(error)).colorScheme.error,
    );
    expect(
      tester.getTopLeft(error).dy,
      lessThan(tester.getTopLeft(find.text('Создать')).dy),
    );
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
