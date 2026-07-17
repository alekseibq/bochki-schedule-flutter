import 'dart:io';

abstract interface class DocumentOpener {
  Future<void> open(File file);
}
