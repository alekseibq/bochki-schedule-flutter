import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('print preset params view model', () {
    late _InMemoryPrintPresetParamsRepository repository;
    late _InMemoryWorkdaysRepository workdaysRepository;
    late _StubPrintScheduleExporter printScheduleExporter;
    late _StubDocumentOpener documentOpener;
    late PrintPresetParamsViewModel viewModel;

    setUp(() {
      repository = _InMemoryPrintPresetParamsRepository(
        const PrintPresetParams(
          workdayId: 'missing',
          textBefore: 'Начало',
          textAfter: 'Конец',
        ),
      );
      workdaysRepository = _InMemoryWorkdaysRepository([
        Workday(
          id: '1',
          name: 'Пятница',
          calendarDate: DateTime(2026, 7, 17),
        ),
      ]);
      printScheduleExporter = _StubPrintScheduleExporter();
      documentOpener = _StubDocumentOpener();
      viewModel = _buildViewModel(
        repository: repository,
        workdaysRepository: workdaysRepository,
        printScheduleExporter: printScheduleExporter,
        documentOpener: documentOpener,
      );
    });

    test('loads params and falls back to first available workday', () async {
      await viewModel.load();

      expect(viewModel.params.textBefore, 'Начало');
      expect(viewModel.initialWorkdayId, '1');
      expect(viewModel.loadErrorMessage, isNull);
    });

    test('returns null initialWorkdayId when no workdays exist', () async {
      workdaysRepository = _InMemoryWorkdaysRepository(const []);
      viewModel = _buildViewModel(
        repository: repository,
        workdaysRepository: workdaysRepository,
        printScheduleExporter: printScheduleExporter,
        documentOpener: documentOpener,
      );

      await viewModel.load();

      expect(viewModel.initialWorkdayId, isNull);
      expect(viewModel.hasAvailableWorkdays, isFalse);
    });

    test('saves params', () async {
      final isSuccess = await viewModel.save(
        workdayId: '1',
        textBefore: 'A',
        textAfter: 'B',
      );

      expect(isSuccess, isTrue);
      expect(
        repository.params.toJson(),
        const PrintPresetParams(
          workdayId: '1',
          textBefore: 'A',
          textAfter: 'B',
        ).toJson(),
      );
    });

    test('opens file through use case', () async {
      final isSuccess = await viewModel.openFile(
        workdayId: '1',
        textBefore: 'A',
        textAfter: 'B',
        groupBy: PrintScheduleGroupBy.byTime,
      );

      expect(isSuccess, isTrue);
      expect(printScheduleExporter.callCount, 1);
      expect(documentOpener.callCount, 1);
    });
  });
}

PrintPresetParamsViewModel _buildViewModel({
  required _InMemoryPrintPresetParamsRepository repository,
  required _InMemoryWorkdaysRepository workdaysRepository,
  required _StubPrintScheduleExporter printScheduleExporter,
  required _StubDocumentOpener documentOpener,
}) {
  final updateUseCase = UpdatePrintPresetParamsUseCase(repository);
  final saveUseCase = SavePrintScheduleFileUseCase(
    updatePrintPresetParamsUseCase: updateUseCase,
    buildPrintScheduleDocumentUseCase: BuildPrintScheduleDocumentUseCase(
      listRichProcedureSessionsUseCase: ListRichProcedureSessionsUseCase(
        listProcedureSessionsUseCase: ListProcedureSessionsUseCase(
          _ProcedureSessionsRepository([
            ProcedureSessionRaw(
              id: '1',
              dayId: '1',
              participantId: '1',
              startTime: '09:00',
              procedureKindId: '1',
            ),
          ]),
        ),
        listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
        listHumansUseCase: ListHumansUseCase(
          _HumansRepository([
            Human(
              id: '1',
              name: 'Иванов Иван',
              isParticipant: true,
              isAssistant: false,
            ),
          ]),
        ),
        listProcedureKindsUseCase: ListProcedureKindsUseCase(
          _ProcedureKindsRepository([
            ProcedureKind(
              id: '1',
              patternId: ProcedureKindPatterns.single.patternId,
              name: 'Бочка',
              capacity: 1,
              participantBusyTime: 30,
              resourceBusyTime: 30,
            ),
          ]),
        ),
        listAssistantsUseCase:
            ListAssistantsUseCase(_EmptyAssistantsRepository()),
      ),
      listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
    ),
    printScheduleExporter: printScheduleExporter,
    appDataDirectory: Directory('/tmp/bochki_schedule_view_model_test'),
  );

  return PrintPresetParamsViewModel(
    getPrintPresetParamsUseCase: GetPrintPresetParamsUseCase(repository),
    updatePrintPresetParamsUseCase: updateUseCase,
    savePrintScheduleFileUseCase: saveUseCase,
    openPrintScheduleFileUseCase: OpenPrintScheduleFileUseCase(
      savePrintScheduleFileUseCase: saveUseCase,
      documentOpener: documentOpener,
    ),
    listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
  );
}

final class _InMemoryPrintPresetParamsRepository
    implements PrintPresetParamsRepository {
  _InMemoryPrintPresetParamsRepository(this._params);

  PrintPresetParams _params;

  PrintPresetParams get params => _params;

  @override
  Future<PrintPresetParams> get() async => _params;

  @override
  Future<PrintPresetParams> update(PrintPresetParams params) async {
    _params = params;
    return _params;
  }
}

final class _InMemoryWorkdaysRepository implements WorkdaysRepository {
  _InMemoryWorkdaysRepository(this._workdays);

  final List<Workday> _workdays;

  @override
  Future<Workday> create(Workday workday) {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(String workdayId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Workday>> list() async => _workdays;

  @override
  Future<Workday> update(Workday workday) {
    throw UnimplementedError();
  }
}

final class _StubPrintScheduleExporter implements PrintScheduleExporter {
  int callCount = 0;

  @override
  Future<File> export({
    required PrintScheduleDocument document,
    required Directory outputDirectory,
  }) async {
    callCount += 1;
    return File('${outputDirectory.path}/test.docx');
  }
}

final class _StubDocumentOpener implements DocumentOpener {
  int callCount = 0;

  @override
  Future<void> open(File file) async {
    callCount += 1;
  }
}

final class _ProcedureSessionsRepository
    implements ProcedureSessionsRepository {
  _ProcedureSessionsRepository(this._sessions);

  final List<ProcedureSessionRaw> _sessions;

  @override
  Future<ProcedureSessionRaw> create(ProcedureSessionRaw procedureSession) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String procedureSessionId) async {}

  @override
  Future<List<ProcedureSessionRaw>> list() async => [..._sessions];

  @override
  Future<ProcedureSessionRaw> update(ProcedureSessionRaw procedureSession) {
    throw UnimplementedError();
  }
}

final class _HumansRepository implements HumansRepository {
  _HumansRepository(this._humans);

  final List<Human> _humans;

  @override
  Future<Human> create({
    required String name,
    required bool isParticipant,
    required bool isAssistant,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String humanId) async {}

  @override
  Future<List<Human>> list() async => [..._humans];

  @override
  Future<Human> update(Human human) {
    throw UnimplementedError();
  }
}

final class _ProcedureKindsRepository implements ProcedureKindsRepository {
  _ProcedureKindsRepository(this._procedureKinds);

  final List<ProcedureKind> _procedureKinds;

  @override
  Future<ProcedureKind> create(ProcedureKind procedureKind) {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(String procedureKindId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ProcedureKind>> list() async => [..._procedureKinds];

  @override
  Future<ProcedureKind> update(ProcedureKind procedureKind) {
    throw UnimplementedError();
  }
}

final class _EmptyAssistantsRepository implements AssistantsRepository {
  @override
  Future<Assistant> create({required String name}) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String assistantId) async {}

  @override
  Future<List<Assistant>> list() async => <Assistant>[];

  @override
  Future<Assistant> update(Assistant assistant) {
    throw UnimplementedError();
  }
}
