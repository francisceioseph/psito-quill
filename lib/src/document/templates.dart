// Os modelos (Fase 4, Etapa 8, D-093): o `estilos.ott` do livro e os `.ott`
// da pasta de modelos do Quill. Um modelo guarda só os estilos (a página, os
// parágrafos, os títulos): ele sai da cópia FODT do documento sem o texto
// (`stylesOnly`), e o motor converte para `.ott`. O Dart nunca escreve ODT.
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../settings/config_dir.dart';

/// O modelo de estilos de um livro, na raiz da pasta `.psitobook`.
const bookTemplateName = 'estilos.ott';

String bookTemplatePath(String bookDir) => '$bookDir/$bookTemplateName';

/// `~/.config/psito-quill/modelos`.
Directory templatesDir() => templatesDirOverride ?? Directory('${quillConfigDir().path}/modelos');

/// Os testes põem os modelos numa pasta deles.
@visibleForTesting
Directory? templatesDirOverride;

@immutable
class TemplateEntry {
  const TemplateEntry({required this.path, required this.name, this.ofBook = false});
  final String path;

  /// O nome do arquivo sem o `.ott`.
  final String name;

  /// O `estilos.ott` do livro aberto.
  final bool ofBook;

  @override
  bool operator ==(Object other) => other is TemplateEntry && other.path == path && other.ofBook == ofBook;
  @override
  int get hashCode => Object.hash(path, ofBook);
}

/// Os modelos: o do livro primeiro (se o livro tem), depois os da pasta, pelo
/// nome.
List<TemplateEntry> listTemplates({String? bookDir, Directory? dir}) {
  final out = <TemplateEntry>[];
  if (bookDir != null && File(bookTemplatePath(bookDir)).existsSync()) {
    out.add(TemplateEntry(path: bookTemplatePath(bookDir), name: bookTemplateName, ofBook: true));
  }
  final folder = dir ?? templatesDir();
  try {
    final files = [
      for (final f in folder.listSync().whereType<File>())
        if (f.path.toLowerCase().endsWith('.ott')) f,
    ]..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    for (final f in files) {
      final file = f.uri.pathSegments.last;
      out.add(TemplateEntry(path: f.path, name: file.substring(0, file.length - 4)));
    }
  } on FileSystemException {
    // Sem a pasta: só o do livro.
  }
  return out;
}

/// Um nome de arquivo para o modelo [name]: sem barras nem os caracteres que
/// os sistemas de arquivos recusam. null se não sobra nada.
String? templateFileName(String name) {
  final clean = name.trim().replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f]'), '').trim();
  if (clean.isEmpty || clean == '.' || clean == '..') return null;
  return '$clean.ott';
}
