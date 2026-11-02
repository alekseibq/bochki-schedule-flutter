import '../../domain/workdays/workday.dart';
import '../../domain/workdays/workdays_validation_exception.dart';
import 'workdays_operations.dart';

typedef WorkdaysIpcInvoker = Future<Object?> Function(
    String method, Object? arguments);

final class IpcWorkdaysOperations implements WorkdaysOperations {
  const IpcWorkdaysOperations(this._invoke);
  final WorkdaysIpcInvoker _invoke;

  @override
  Future<List<Workday>> list() async {
    final snapshot = Map<String, dynamic>.from(
      await _invoke('directorySnapshot', 'workdays') as Map,
    );
    return (snapshot['entries'] as List)
        .map((value) => _fromMap(Map<String, dynamic>.from(value as Map)))
        .toList(growable: false);
  }

  @override
  Future<Workday> create(Workday value) async {
    await _mutate('create', entry: _toMap(value));
    return value;
  }

  @override
  Future<Workday> update(Workday value) async {
    await _mutate('update', id: value.id, entry: _toMap(value));
    return value;
  }

  @override
  Future<int> countReferences(String id) async =>
      await _invoke('workdayReferences', id) as int? ?? 0;

  @override
  Future<void> delete(String id) => _mutate('delete', id: id);

  @override
  Future<List<double>> loadColumnWidths() async {
    final snapshot = Map<String, dynamic>.from(
      await _invoke('directorySnapshot', 'workdays') as Map,
    );
    return (snapshot['workdaysColumnWidths'] as List? ?? const [])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList(growable: false);
  }

  @override
  Future<void> saveColumnWidths(List<double> widths) =>
      _invoke('updateWorkdaysColumnWidths', widths);

  Future<void> _mutate(String action,
      {String? id, Map<String, dynamic>? entry}) async {
    final result = Map<String, dynamic>.from(await _invoke('directoryMutate', {
      'directory': 'workdays',
      'action': action,
      if (id != null) 'id': id,
      'entry': entry ?? const <String, dynamic>{},
    }) as Map);
    if (result['ok'] != true) {
      if (result['validation'] == true) {
        throw WorkdaysValidationException(result['error'] as String);
      }
      throw StateError(
          result['error'] as String? ?? 'Не удалось сохранить изменения.');
    }
  }

  Workday _fromMap(Map<String, dynamic> map) => Workday(
        id: map['id'] as String,
        name: map['name'] as String,
        calendarDate: DateTime.parse(map['date'] as String),
      );
  Map<String, dynamic> _toMap(Workday value) => {
        'name': value.name,
        'date': value.calendarDate.toIso8601String().substring(0, 10),
      };
}
