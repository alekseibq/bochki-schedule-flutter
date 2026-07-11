import '../named_directory/named_directory_entry.dart';

import 'human.dart';
import 'humans_repository.dart';

final class ListHumansUseCase {
  const ListHumansUseCase(this._repository);

  final HumansRepository _repository;

  Future<List<Human>> execute() async {
    final humans = await _repository.list();
    humans.sort(
      (left, right) => NamedDirectoryEntry.sortKeyForName(left.name)
          .compareTo(NamedDirectoryEntry.sortKeyForName(right.name)),
    );
    return List<Human>.unmodifiable(humans);
  }
}
