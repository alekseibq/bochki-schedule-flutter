import 'dart:async';

import 'package:bochki_schedule_app/src/presentation/desktop_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_retriever/screen_retriever.dart';

void main() {
  group('windowKindFromArguments', () {
    test('reads a statistics window argument', () {
      expect(
        windowKindFromArguments('{"kind":"procedureStatistics"}'),
        DesktopWindowKind.procedureStatistics,
      );
    });

    test('reads directory and editor window arguments', () {
      expect(
        windowKindFromArguments('{"kind":"participants"}'),
        DesktopWindowKind.participants,
      );
      expect(
        windowKindFromArguments('{"kind":"procedureKindEditor"}'),
        DesktopWindowKind.procedureKindEditor,
      );
    });

    test('treats invalid arguments as the main window', () {
      expect(windowKindFromArguments('invalid'), DesktopWindowKind.main);
    });

    test('reads a parent window ID when it is present', () {
      final descriptor = windowDescriptorFromArguments(
        '{"kind":"procedureKindEditor","parentWindowId":"directory",'
        '"ancestorWindowIds":["directory","main"]}',
      );

      expect(descriptor.kind, DesktopWindowKind.procedureKindEditor);
      expect(descriptor.parentWindowId, 'directory');
      expect(descriptor.ancestorWindowIds, ['directory', 'main']);
    });
  });

  group('mutateProcedureKindDirectory', () {
    test('deletes by ID without decoding a missing form entry', () async {
      final deletedIds = <String>[];

      await mutateProcedureKindDirectory(
        action: 'delete',
        id: 'procedure-1',
        entry: const {},
        create: (_) async {},
        update: (_) async {},
        delete: (id) async => deletedIds.add(id),
      );

      expect(deletedIds, ['procedure-1']);
    });

    test('passes curated times through a create command', () async {
      dynamic created;

      await mutateProcedureKindDirectory(
        action: 'create',
        id: null,
        entry: const {
          'patternId': 'curated',
          'name': 'Бочка',
          'shortName': 'Бочка',
          'capacity': 2,
          'participantBusyTime': 30,
          'assistantBusyTime': 10,
          'resourceBusyTime': 15,
        },
        create: (kind) async => created = kind,
        update: (_) async {},
        delete: (_) async {},
      );

      expect(created.id, 'new');
      expect(created.assistantBusyTime, 10);
      expect(created.resourceBusyTime, 15);
    });
  });

  group('descendantWindowIdsInCloseOrder', () {
    test('closes deepest descendants before their parents', () {
      expect(
        descendantWindowIdsInCloseOrder(
          parentWindowId: 'main',
          parentWindowIds: const {
            'directory': 'main',
            'editor': 'directory',
            'statistics': 'main',
          },
        ),
        ['editor', 'directory', 'statistics'],
      );
    });

    test('ignores windows outside the current window subtree', () {
      expect(
        descendantWindowIdsInCloseOrder(
          parentWindowId: 'main',
          parentWindowIds: const {'other-child': 'other-parent'},
        ),
        isEmpty,
      );
    });
  });

  group('requestDescendantWindowCloses', () {
    test('requests every descendant in close order', () async {
      final requestedIds = <String>[];

      requestDescendantWindowCloses(
        windowIds: const ['editor', 'directory'],
        requestClose: (id) async => requestedIds.add(id),
        onError: (_, __, ___) {},
      );

      expect(requestedIds, ['editor', 'directory']);
    });

    test('continues when a descendant has already disappeared', () async {
      final requestedIds = <String>[];
      final errors = <Object>[];

      requestDescendantWindowCloses(
        windowIds: const ['editor', 'directory'],
        requestClose: (id) async {
          requestedIds.add(id);
          if (id == 'editor') throw StateError('window not found');
        },
        onError: (_, error, __) => errors.add(error),
      );
      await Future<void>.delayed(Duration.zero);

      expect(requestedIds, ['editor', 'directory']);
      expect(errors, hasLength(1));
    });

    test('does not wait for an unresponsive descendant', () async {
      final requestedIds = <String>[];
      final neverCompletes = Completer<void>();

      requestDescendantWindowCloses(
        windowIds: const ['editor', 'directory'],
        requestClose: (id) {
          requestedIds.add(id);
          return id == 'editor' ? neverCompletes.future : Future<void>.value();
        },
        onError: (_, __, ___) {},
      );

      expect(requestedIds, ['editor', 'directory']);
    });
  });

  group('closeWindowAfterSchedulingCleanup', () {
    test('closes natively without waiting for descendant or parent IPC',
        () async {
      final descendantClose = Completer<void>();
      final parentActivation = Completer<void>();
      var nativeCloseRequests = 0;

      await closeWindowAfterSchedulingCleanup(
        requestDescendantCloses: () => descendantClose.future,
        activateParent: () => parentActivation.future,
        closeNativeWindow: () async => nativeCloseRequests += 1,
        onCleanupError: (_, __) {},
      );

      expect(nativeCloseRequests, 1);
    });

    test('reports a cleanup failure without cancelling native close', () async {
      final cleanupErrors = <Object>[];
      var nativeCloseRequests = 0;

      await closeWindowAfterSchedulingCleanup(
        requestDescendantCloses: () async => throw StateError('stale child'),
        closeNativeWindow: () async => nativeCloseRequests += 1,
        onCleanupError: (error, _) => cleanupErrors.add(error),
      );
      await Future<void>.delayed(Duration.zero);

      expect(nativeCloseRequests, 1);
      expect(cleanupErrors, hasLength(1));
    });
  });

  group('child window placement', () {
    const primary = Display(
      id: 'primary',
      size: Size(1920, 1080),
      visiblePosition: Offset.zero,
      visibleSize: Size(1920, 1040),
    );
    const secondary = Display(
      id: 'secondary',
      size: Size(1600, 900),
      visiblePosition: Offset(1920, 0),
      visibleSize: Size(1600, 860),
    );

    test('selects the display containing the parent window center', () {
      expect(
        displayForParentBounds(
          primaryDisplay: primary,
          displays: const [primary, secondary],
          parentBounds: const Rect.fromLTWH(2100, 100, 800, 600),
        ),
        secondary,
      );
    });

    test('centers the child in the display work area', () {
      expect(
        centeredWindowPosition(
          workArea: displayWorkArea(secondary),
          windowSize: const Size(920, 640),
        ),
        const Offset(2260, 110),
      );
    });

    test('uses the primary display when parent bounds are unavailable', () {
      expect(
        displayForParentBounds(
          primaryDisplay: primary,
          displays: const [primary, secondary],
          parentBounds: null,
        ),
        primary,
      );
    });
  });

  test('creates child windows hidden until their final bounds are ready', () {
    expect(
      childWindowConfiguration('{"kind":"participants"}').hiddenAtLaunch,
      isTrue,
    );
  });

  testWidgets('free-time results scroll vertically while keeping a scrollbar',
      (tester) async {
    final gaps = List<Map<String, dynamic>>.generate(
      20,
      (index) => {
        'day': {'id': 'day', 'name': 'День', 'date': '2026-08-25'},
        'human': {
          'id': 'human-$index',
          'name': 'Человек $index',
          'shortName': 'Ч.$index',
          'isParticipant': true,
          'isAssistant': false,
        },
        'start': '08:00',
        'end': '09:00',
        'duration': '1 ч',
      },
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 120,
          child: FreeTimeResultsTable(
            gaps: gaps,
            onOccupy: (_) async {},
          ),
        ),
      ),
    ));

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    final verticalScrollView = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .firstWhere((view) => view.scrollDirection == Axis.vertical);

    expect(scrollbar.thumbVisibility, isTrue);
    expect(
      verticalScrollView.controller!.position.maxScrollExtent,
      greaterThan(0),
    );

    verticalScrollView.controller!.jumpTo(50);
    await tester.pump();

    expect(verticalScrollView.controller!.offset, 50);
  });

  testWidgets('directory child content opens a localized date picker',
      (tester) async {
    await tester.pumpWidget(
      DirectoryChildWindowScaffold(
        title: 'Дни',
        absorbing: false,
        builder: (contentContext) => Center(
          child: FilledButton(
            onPressed: () => showDatePicker(
              context: contentContext,
              initialDate: DateTime(2026, 8, 25),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            ),
            child: const Text('Выбрать дату'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Выбрать дату'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
