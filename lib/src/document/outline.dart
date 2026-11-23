// A estrutura do documento: os títulos, com o nível. Quem a preenche é a
// Etapa 5 da Fase 2B (lida de uma cópia temporária do documento); o painel
// Estrutura só a mostra.
import 'package:flutter/foundation.dart';

@immutable
class OutlineEntry {
  const OutlineEntry({required this.level, required this.text, this.page = 1});

  /// 1 para Título 1, 2 para Título 2...
  final int level;
  final String text;

  /// A página onde o título estava na cópia (pelas quebras de página que o
  /// LibreOffice escreve, `text:soft-page-break`).
  final int page;

  @override
  bool operator ==(Object other) => other is OutlineEntry && other.level == level && other.text == text && other.page == page;

  @override
  int get hashCode => Object.hash(level, text, page);
}

/// O título onde o cursor está: o último que começa na página [page] ou
/// antes. null se o cursor está antes do primeiro.
int? currentHeading(List<OutlineEntry> entries, int? page) {
  if (page == null) return null;
  int? found;
  for (var i = 0; i < entries.length; i++) {
    if (entries[i].page > page) break;
    found = i;
  }
  return found;
}
