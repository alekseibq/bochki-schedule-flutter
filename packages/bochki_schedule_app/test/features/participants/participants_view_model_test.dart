import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParticipantsViewModel', () {
    late _InMemoryParticipantsRepository repository;
    late ParticipantsViewModel viewModel;

    setUp(() {
      repository = _InMemoryParticipantsRepository(
        participants: [
          Participant(id: '1', name: 'Анна'),
        ],
      );
      viewModel = ParticipantsViewModel(
        listParticipantsUseCase: ListParticipantsUseCase(repository),
        createParticipantUseCase: CreateParticipantUseCase(repository),
        updateParticipantUseCase: UpdateParticipantUseCase(repository),
        deleteParticipantUseCase: DeleteParticipantUseCase(repository),
      );
    });

    test('loads participants', () async {
      await viewModel.loadParticipants();

      expect(viewModel.participants.map((participant) => participant.name), [
        'Анна',
      ]);
      expect(viewModel.loadErrorMessage, isNull);
    });

    test('adds participant', () async {
      await viewModel.loadParticipants();

      final isSuccess = await viewModel.createParticipant('Борис');

      expect(isSuccess, isTrue);
      expect(viewModel.participants.map((participant) => participant.name), [
        'Анна',
        'Борис',
      ]);
      expect(viewModel.formErrorMessage, isNull);
    });

    test('updates participant', () async {
      await viewModel.loadParticipants();

      final isSuccess = await viewModel.updateParticipant(
        participantId: '1',
        rawName: 'Анна Петрова',
      );

      expect(isSuccess, isTrue);
      expect(viewModel.participants.single.name, 'Анна Петрова');
    });

    test('deletes participant', () async {
      await viewModel.loadParticipants();

      final isSuccess = await viewModel.deleteParticipant('1');

      expect(isSuccess, isTrue);
      expect(viewModel.participants, isEmpty);
    });

    test('empty name sets validation error', () async {
      await viewModel.loadParticipants();

      final isSuccess = await viewModel.createParticipant('   ');

      expect(isSuccess, isFalse);
      expect(viewModel.formErrorMessage, 'Введите имя участника.');
    });
  });
}

final class _InMemoryParticipantsRepository implements ParticipantsRepository {
  _InMemoryParticipantsRepository({
    List<Participant>? participants,
  }) : _participants = [...?participants] {
    if (_participants.isNotEmpty) {
      final maxId = _participants
          .map((participant) => int.parse(participant.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Participant> _participants;
  int _nextId = 1;

  @override
  Future<Participant> create({
    required String name,
  }) async {
    final participant = Participant(
      id: (_nextId++).toString(),
      name: name,
    );
    _participants.add(participant);
    return participant;
  }

  @override
  Future<void> delete(String participantId) async {
    _participants.removeWhere((participant) => participant.id == participantId);
  }

  @override
  Future<List<Participant>> list() async {
    return [..._participants];
  }

  @override
  Future<Participant> update(Participant participant) async {
    final index = _participants.indexWhere(
      (candidate) => candidate.id == participant.id,
    );
    if (index != -1) {
      _participants[index] = participant;
    }
    return participant;
  }
}
