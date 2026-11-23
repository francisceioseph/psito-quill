// Peças de teste: o kit falso montado com o controlador, a área de trabalho,
// as janelas de arquivo falsas e as preferências na memória.
import 'dart:io';

import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/text_clipboard.dart';
import 'package:psito_quill/src/document/workspace.dart';
import 'package:psito_quill/src/files/app_window.dart';
import 'package:psito_quill/src/files/file_dialogs.dart';
import 'package:psito_quill/src/files/lo_lock.dart';
import 'package:psito_quill/src/files/recent_files.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/settings/settings.dart';

class FakeFileDialogs implements FileDialogs {
  /// O que as janelas respondem (null: cancelou).
  String? openAnswer, saveAnswer, imageAnswer;
  final opens = <String>[];
  final images = <String>[];

  @override
  Future<String?> pickImage({required String label}) async {
    images.add(label);
    return imageAnswer;
  }
  final saves = <String>[];

  @override
  Future<String?> pickOpen({required String label}) async {
    opens.add(label);
    return openAnswer;
  }

  @override
  Future<String?> pickSave({
    required String suggestedName,
    String? initialDirectory,
    required Map<DocFormat, String> labels,
  }) async {
    saves.add(suggestedName);
    return saveAnswer;
  }
}

class FakeAppWindow implements AppWindow {
  final titles = <String>[];

  @override
  void setTitle(String title) {
    if (titles.isEmpty || titles.last != title) titles.add(title);
  }
}

const testProfileUrl = 'file:///home/eu/.config/psito-quill/lo-profile';
const testHost = 'esta-maquina';

/// Tudo montado, numa pasta temporária (apagada no fim).
class Harness {
  Harness({FakeQuillKit? kit}) : kit = kit ?? FakeQuillKit() {
    dir = Directory.systemTemp.createTempSync('quill-teste-');
    doc = DocumentController(this.kit, clipboard: clipboard)..start();
    recents = RecentFiles(File('${dir.path}/recentes.json'));
    workspace = Workspace(
      doc: doc,
      recents: recents,
      dialogs: dialogs,
      locks: LockInspector(profileUrl: testProfileUrl, hostname: testHost),
    );
  }

  final FakeQuillKit kit;
  final clipboard = MemoryTextClipboard();
  final dialogs = FakeFileDialogs();
  final window = FakeAppWindow();
  final settings = Settings(null);
  late final Directory dir;
  late final DocumentController doc;
  late final RecentFiles recents;
  late final Workspace workspace;

  /// Um arquivo de verdade na pasta temporária.
  String file(String name) {
    final f = File('${dir.path}/$name')..writeAsStringSync('x');
    return f.path;
  }

  /// Uma trava do LibreOffice ao lado de [path].
  void lock(String path, {String host = testHost, String profile = testProfileUrl, String user = 'outra'}) =>
      LoLock.fileFor(path).writeAsStringSync(',$user,$host,22.11.2026 10:00,$profile;');

  void dispose() {
    workspace.dispose();
    doc.dispose();
    recents.dispose();
    settings.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}
