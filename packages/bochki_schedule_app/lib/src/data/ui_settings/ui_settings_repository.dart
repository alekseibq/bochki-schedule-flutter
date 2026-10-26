import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

final class UiSettings {
  const UiSettings({
    this.uiScale = 1.1,
    this.shouldResetUiDimensionsOnStart = false,
    this.windowSizes = const {},
    this.procedureSessionsColumnWidths = const [],
    this.procedureKindsColumnWidths = const [],
    this.quickReassignmentsColumnWidths = const [],
    this.workdaysColumnWidths = const [],
  });

  final double uiScale;
  final bool shouldResetUiDimensionsOnStart;
  final Map<String, Map<String, double>> windowSizes;
  final List<double> procedureSessionsColumnWidths;
  final List<double> procedureKindsColumnWidths;
  final List<double> quickReassignmentsColumnWidths;
  final List<double> workdaysColumnWidths;

  UiSettings copyWith({
    double? uiScale,
    bool? shouldResetUiDimensionsOnStart,
    Map<String, Map<String, double>>? windowSizes,
    List<double>? procedureSessionsColumnWidths,
    List<double>? procedureKindsColumnWidths,
    List<double>? quickReassignmentsColumnWidths,
    List<double>? workdaysColumnWidths,
  }) =>
      UiSettings(
        uiScale: uiScale ?? this.uiScale,
        shouldResetUiDimensionsOnStart: shouldResetUiDimensionsOnStart ??
            this.shouldResetUiDimensionsOnStart,
        windowSizes: windowSizes ?? this.windowSizes,
        procedureSessionsColumnWidths:
            procedureSessionsColumnWidths ?? this.procedureSessionsColumnWidths,
        procedureKindsColumnWidths:
            procedureKindsColumnWidths ?? this.procedureKindsColumnWidths,
        quickReassignmentsColumnWidths: quickReassignmentsColumnWidths ??
            this.quickReassignmentsColumnWidths,
        workdaysColumnWidths: workdaysColumnWidths ?? this.workdaysColumnWidths,
      );

  Map<String, Object?> toJson() => {
        'version': 1,
        'uiScale': uiScale,
        'shouldResetUiDimensionsOnStart': shouldResetUiDimensionsOnStart,
        'windowSizes': windowSizes,
        'procedureSessionsColumnWidths': procedureSessionsColumnWidths,
        'procedureKindsColumnWidths': procedureKindsColumnWidths,
        'quickReassignmentsColumnWidths': quickReassignmentsColumnWidths,
        'workdaysColumnWidths': workdaysColumnWidths,
      };

  factory UiSettings.fromJson(Object? value) {
    if (value is! Map)
      throw const FormatException('UI settings must be an object.');
    final scale = (value['uiScale'] as num?)?.toDouble() ?? 1.1;
    if (scale < 1 || scale > 1.5)
      throw const FormatException('Invalid UI scale.');
    final rawSizes = value['windowSizes'];
    final sizes = <String, Map<String, double>>{};
    if (rawSizes is Map) {
      for (final entry in rawSizes.entries) {
        if (entry.value is! Map) continue;
        final width = (entry.value['width'] as num?)?.toDouble();
        final height = (entry.value['height'] as num?)?.toDouble();
        if (width != null && height != null && width > 0 && height > 0) {
          sizes[entry.key.toString()] = {'width': width, 'height': height};
        }
      }
    }
    final widths = (value['procedureSessionsColumnWidths'] as List? ?? const [])
        .whereType<num>()
        .map((width) => width.toDouble())
        .toList(growable: false);
    final procedureKindsWidths =
        (value['procedureKindsColumnWidths'] as List? ?? const [])
            .whereType<num>()
            .map((width) => width.toDouble())
            .toList(growable: false);
    final quickReassignmentsWidths =
        (value['quickReassignmentsColumnWidths'] as List? ?? const [])
            .whereType<num>()
            .map((width) => width.toDouble())
            .toList(growable: false);
    final workdaysWidths = (value['workdaysColumnWidths'] as List? ?? const [])
        .whereType<num>()
        .map((width) => width.toDouble())
        .toList(growable: false);
    return UiSettings(
      uiScale: scale,
      shouldResetUiDimensionsOnStart:
          value['shouldResetUiDimensionsOnStart'] as bool? ?? false,
      windowSizes: sizes,
      procedureSessionsColumnWidths: widths,
      procedureKindsColumnWidths: procedureKindsWidths,
      quickReassignmentsColumnWidths: quickReassignmentsWidths,
      workdaysColumnWidths: workdaysWidths,
    );
  }
}

final class UiSettingsRepository {
  UiSettingsRepository({required File file, required SafeFileWriter writer})
      : _file = file,
        _writer = writer;

  final File _file;
  final SafeFileWriter _writer;
  UiSettings _settings = const UiSettings();
  bool _isLoaded = false;
  Timer? _saveDebounce;
  Completer<void>? _pendingSave;
  Future<void> _writeTail = Future<void>.value();

  UiSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  Future<bool> load({required double legacyUiScale}) async {
    if (!await _file.exists()) {
      _settings = UiSettings(uiScale: legacyUiScale);
      _isLoaded = true;
      await save();
      return true;
    }
    try {
      _settings = UiSettings.fromJson(jsonDecode(await _file.readAsString()));
      _isLoaded = true;
      if (_settings.shouldResetUiDimensionsOnStart) {
        _settings = const UiSettings();
        await save();
        return true;
      }
      return false;
    } catch (_) {
      _settings = const UiSettings();
      _isLoaded = true;
      await save();
      return true;
    }
  }

  Future<void> update(UiSettings settings) {
    _settings = settings;
    _saveDebounce?.cancel();
    final pending = _pendingSave ??= Completer<void>();
    _saveDebounce = Timer(const Duration(milliseconds: 300), _enqueuePending);
    return pending.future;
  }

  Future<void> save() => _enqueueWrite(_settings);

  Future<void> flush() async {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _enqueuePending();
    await _writeTail;
  }

  void dispose() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _pendingSave?.complete();
    _pendingSave = null;
  }

  void _enqueuePending() {
    _saveDebounce = null;
    final pending = _pendingSave;
    if (pending == null) return;
    _pendingSave = null;
    _enqueueWrite(_settings)
        .then(pending.complete, onError: pending.completeError);
  }

  Future<void> _enqueueWrite(UiSettings settings) {
    final contents =
        const JsonEncoder.withIndent('  ').convert(settings.toJson());
    _writeTail = _writeTail.catchError((_) {}).then(
          (_) => _writer.writeString(_file, contents),
        );
    return _writeTail;
  }
}
