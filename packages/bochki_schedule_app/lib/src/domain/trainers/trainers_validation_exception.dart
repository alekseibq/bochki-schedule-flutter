import '../named_directory/named_directory_validation_exception.dart';

final class TrainersValidationException
    extends NamedDirectoryValidationException {
  const TrainersValidationException(String message) : super(message);

  @override
  String get message => super.message;
}
