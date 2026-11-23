// Vale para todos os testes de test/: as cópias temporárias do documento
// (D-044) vão para uma pasta dos testes, e não para o $XDG_RUNTIME_DIR do
// usuário (onde outro processo de teste poderia apagá-las no meio).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final dir = Directory.systemTemp.createTempSync('quill-copias-');
  DocumentController.copyDirOverride = dir.path;
  // Depois de todos os testes do arquivo (o testMain só os declara).
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Já foi.
    }
  });
  await testMain();
}
