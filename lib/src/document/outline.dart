// A estrutura do documento: os títulos, com o nível. Quem a preenche é a
// Etapa 5 da Fase 2B (lida de uma cópia temporária do documento); o painel
// Estrutura só a mostra.
import 'package:flutter/foundation.dart';

@immutable
class OutlineEntry {
  const OutlineEntry({required this.level, required this.text, this.page = 1, String? searchKey, this.occurrence = 0})
      : searchKey = searchKey ?? text;

  /// 1 para Título 1, 2 para Título 2...
  final int level;
  final String text;

  /// A página onde o título estava na cópia (pelas quebras de página que o
  /// LibreOffice escreve, `text:soft-page-break`).
  final int page;

  /// O que se procura no motor para chegar ao título: o texto dele como está
  /// no parágrafo, até a primeira tabulação ou quebra de linha (a busca do
  /// motor não as acha pelo espaço que a Estrutura mostra).
  final String searchKey;

  /// Quantas vezes o [searchKey] aparece no texto antes deste título (num
  /// parágrafo com "Cena 10", ou num título repetido): o salto vai ao começo
  /// do documento e procura uma vez a mais que isso.
  final int occurrence;

  @override
  bool operator ==(Object other) =>
      other is OutlineEntry &&
      other.level == level &&
      other.text == text &&
      other.page == page &&
      other.searchKey == searchKey &&
      other.occurrence == occurrence;

  @override
  int get hashCode => Object.hash(level, text, page, searchKey, occurrence);
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
