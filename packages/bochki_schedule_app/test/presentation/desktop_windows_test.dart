import 'package:bochki_schedule_app/src/presentation/desktop_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
