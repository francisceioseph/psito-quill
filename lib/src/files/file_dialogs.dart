// A porta das janelas de abrir e salvar (Ports & Adapters): o app usa o
// file_selector (o seletor do GTK), e os testes um falso.
import 'package:file_selector/file_selector.dart';

/// Os formatos que o Quill abre e salva na Fase 1.
enum DocFormat {
  odt('odt', 'application/vnd.oasis.opendocument.text'),
  docx('docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');

  const DocFormat(this.extension, this.mime);
  final String extension, mime;

  static DocFormat? ofPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    for (final f in values) {
      if (f.extension == ext) return f;
    }
    return null;
  }
}

abstract interface class FileDialogs {
  /// O caminho escolhido, ou null se cancelou.
  Future<String?> pickOpen({required String label});

  /// O caminho escolhido (já com a extensão do formato), ou null.
  Future<String?> pickSave({required String suggestedName, String? initialDirectory, required Map<DocFormat, String> labels});
}

class SystemFileDialogs implements FileDialogs {
  const SystemFileDialogs();

  @override
  Future<String?> pickOpen({required String label}) async {
    final file = await openFile(acceptedTypeGroups: [
      XTypeGroup(label: label, extensions: [for (final f in DocFormat.values) f.extension]),
    ]);
    return file?.path;
  }

  @override
  Future<String?> pickSave({
    required String suggestedName,
    String? initialDirectory,
    required Map<DocFormat, String> labels,
  }) async {
    final groups = [
      for (final f in DocFormat.values) XTypeGroup(label: labels[f], extensions: [f.extension], mimeTypes: [f.mime]),
    ];
    final location = await getSaveLocation(
      acceptedTypeGroups: groups,
      suggestedName: suggestedName,
      initialDirectory: initialDirectory,
    );
    if (location == null) return null;
    var path = location.path;
    if (DocFormat.ofPath(path) == null) {
      // Sem extensão: a do filtro escolhido, ou ODT.
      final chosen = groups.indexWhere((g) => g.label == location.activeFilter?.label);
      path += '.${(chosen < 0 ? DocFormat.odt : DocFormat.values[chosen]).extension}';
    }
    return path;
  }
}
