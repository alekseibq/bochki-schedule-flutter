final class PrintPresetParams {
  const PrintPresetParams({
    required this.workdayId,
    required this.textBefore,
    required this.textAfter,
  });

  static const PrintPresetParams defaults = PrintPresetParams(
    workdayId: '',
    textBefore: '',
    textAfter: '',
  );

  final String workdayId;
  final String textBefore;
  final String textAfter;

  factory PrintPresetParams.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Print preset params must be an object.');
    }

    return PrintPresetParams(
      workdayId: _readString(json['workdayId'], fieldName: 'workdayId'),
      textBefore: _readString(json['textBefore'], fieldName: 'textBefore'),
      textAfter: _readString(json['textAfter'], fieldName: 'textAfter'),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'workdayId': workdayId,
      'textBefore': textBefore,
      'textAfter': textAfter,
    };
  }

  PrintPresetParams copyWith({
    String? workdayId,
    String? textBefore,
    String? textAfter,
  }) {
    return PrintPresetParams(
      workdayId: workdayId ?? this.workdayId,
      textBefore: textBefore ?? this.textBefore,
      textAfter: textAfter ?? this.textAfter,
    );
  }

  static String _readString(
    Object? value, {
    required String fieldName,
  }) {
    if (value is! String) {
      throw FormatException(
        'Print preset params field "$fieldName" must be a string.',
      );
    }
    return value;
  }
}
