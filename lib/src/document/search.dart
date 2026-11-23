// Localizar e substituir: a pergunta e os argumentos do `.uno:ExecuteSearch`.
//
// Medido na 24.2 (D-031): o comando 0 acha a próxima e a seleciona, o 1 acha
// todas (e as seleciona juntas), o 2 substitui a selecionada e acha a
// próxima, o 3 substitui todas. A expressão regular é o AlgorithmType2 = 2.
// Sem a TransliterateFlags, a busca ignora maiúsculas.
import 'dart:convert';

import 'package:flutter/foundation.dart';

enum SearchCommand { next, all, replace, replaceAll }

@immutable
class SearchQuery {
  const SearchQuery(this.text, {this.matchCase = false, this.wholeWord = false, this.regex = false});

  final String text;
  final bool matchCase, wholeWord, regex;

  bool get isEmpty => text.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.text == text &&
      other.matchCase == matchCase &&
      other.wholeWord == wholeWord &&
      other.regex == regex;

  @override
  int get hashCode => Object.hash(text, matchCase, wholeWord, regex);
}

/// O JSON do `.uno:ExecuteSearch`.
String searchArgs(SearchQuery q, SearchCommand command, {String replacement = '', bool backward = false}) {
  Map<String, Object> v(String type, Object value) => {'type': type, 'value': value};
  return jsonEncode({
    'SearchItem.SearchString': v('string', q.text),
    'SearchItem.ReplaceString': v('string', replacement),
    'SearchItem.Backward': v('boolean', backward),
    'SearchItem.Command': v('long', command.index),
    'SearchItem.WordOnly': v('boolean', q.wholeWord),
    // SearchAlgorithms2: 1 = absoluta, 2 = expressão regular. O antigo
    // AlgorithmType vai junto: 0 = absoluta, 1 = expressão regular.
    'SearchItem.AlgorithmType2': v('short', q.regex ? 2 : 1),
    'SearchItem.AlgorithmType': v('short', q.regex ? 1 : 0),
    // IGNORE_CASE = 256. Zero: diferencia maiúsculas.
    'SearchItem.TransliterateFlags': v('long', q.matchCase ? 0 : 256),
  });
}
