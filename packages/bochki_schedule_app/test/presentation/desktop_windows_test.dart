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
