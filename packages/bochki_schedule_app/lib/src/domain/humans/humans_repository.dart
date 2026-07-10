import 'human.dart';

abstract interface class HumansRepository {
  Future<List<Human>> list();

  Future<Human> create({
    required String name,
    required bool isParticipant,
    required bool isAssistant,
  });

  Future<Human> update(Human human);

  Future<void> delete(String humanId);
}
