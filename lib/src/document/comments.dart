// Os comentários do documento (D-088): a lista que o motor manda (o
// `.uno:ViewAnnotations` e o callback 32) arrumada em conversas, na ordem do
// texto. Funções puras, testadas em test/unit/comments_test.dart.
import 'dart:convert';

import '../kit/quill_kit.dart';

/// Um comentário e as respostas dele, na ordem em que vieram.
class CommentThread {
  const CommentThread(this.root, this.replies);
  final DocComment root;
  final List<DocComment> replies;

  /// O motor marca o resolvido no comentário de cima.
  bool get resolved => root.resolved;
}

/// As conversas na ordem do texto: pela linha do trecho, depois pela
/// coluna. Uma resposta cujo comentário sumiu vira conversa sozinha.
List<CommentThread> commentThreads(List<DocComment> comments) {
  final ids = {for (final c in comments) c.id};
  final roots = [for (final c in comments) if (!c.isReply || !ids.contains(c.parentId)) c];
  // A resposta de uma resposta conta na conversa do comentário de cima.
  final parent = {for (final c in comments) c.id: c.parentId};
  String top(DocComment c) {
    var id = c.id;
    final seen = <String>{};
    while (seen.add(id)) {
      final p = parent[id] ?? '';
      if (p.isEmpty || !ids.contains(p)) break;
      id = p;
    }
    return id;
  }

  final replies = <String, List<DocComment>>{};
  for (final c in comments) {
    if (c.isReply && ids.contains(c.parentId)) (replies[top(c)] ??= []).add(c);
  }
  final threads = [for (final r in roots) CommentThread(r, replies[r.id] ?? const [])];
  threads.sort((a, b) {
    final pa = a.root.range.firstOrNull?.topLeft ?? a.root.anchor?.topLeft;
    final pb = b.root.range.firstOrNull?.topLeft ?? b.root.anchor?.topLeft;
    if (pa == null || pb == null) return (pa == null ? 1 : 0) - (pb == null ? 1 : 0);
    // Na mesma linha (o topo perto), vale a coluna.
    if ((pa.dy - pb.dy).abs() > 20) return pa.dy.compareTo(pb.dy);
    return pa.dx.compareTo(pb.dx);
  });
  return threads;
}

/// A lista depois de um callback 32.
List<DocComment> applyCommentChange(List<DocComment> comments, CommentChanged e) {
  final i = comments.indexWhere((c) => c.id == e.comment.id);
  if (e.action == CommentAction.remove) {
    if (i < 0) return comments;
    return [...comments]..removeAt(i);
  }
  if (i < 0) return [...comments, e.comment];
  return [...comments]..[i] = e.comment;
}

/// Os argumentos de um comando de comentário, em JSON do LibreOffice.
String commentArgs({String? id, String? text}) => jsonEncode({
      if (id != null) 'Id': {'type': 'string', 'value': id},
      if (text != null) 'Text': {'type': 'string', 'value': text},
    });

/// Quantos comentários abertos (não resolvidos, sem contar as respostas) há
/// no `content.xml` de um capítulo fechado: os `office:annotation` sem
/// `loext:parent-name` e sem `loext:resolved="true"`.
int openCommentsInContent(String contentXml) {
  var n = 0;
  for (final m in _annotation.allMatches(contentXml)) {
    final tag = m[0]!;
    if (tag.contains('loext:parent-name=')) continue;
    if (tag.contains('loext:resolved="true"')) continue;
    n++;
  }
  return n;
}

final _annotation = RegExp(r'<office:annotation(?=[\s>/])[^>]*>');
