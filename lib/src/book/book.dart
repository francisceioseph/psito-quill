// O livro (Fase 3, D-071): uma pasta `.psitobook` com o `livro.json` e um ODT
// por capítulo.
//
//   Dustland.psitobook/
//     livro.json      o título, a árvore (partes e capítulos), o status, o
//                     rótulo, a sinopse e as palavras de cada capítulo
//     capitulos/      001-a-poeira.odt, ...
//     lixeira/        o que se apagou no fichário (nunca se apaga de vez)
//
// A ordem é a do `livro.json`; o número no nome do arquivo é só para quem
// olha a pasta. Só o capítulo da tela (e os das abas) fica no motor.

/// Parte ou capítulo.
enum BookNodeKind { part, chapter }

/// Onde o capítulo está na escrita.
enum ChapterStatus { draft, revision, done }

class BookNode {
  BookNode({
    required this.id,
    required this.kind,
    required this.title,
    this.file,
    this.status = ChapterStatus.draft,
    this.label,
    this.synopsis = '',
    this.words = 0,
    this.wordsStamp = 0,
    List<BookNode>? children,
  }) : children = children ?? [];

  /// Único no livro e estável (o arquivo pode mudar de nome).
  final String id;
  final BookNodeKind kind;
  String title;

  /// O ODT do capítulo, relativo à pasta do livro ("capitulos/001-x.odt").
  String? file;
  ChapterStatus status;

  /// O rótulo de cor: o índice nos rótulos do tema (`labels`); null sem rótulo.
  int? label;
  String synopsis;

  /// As palavras do capítulo, e a data do arquivo (milissegundos) em que
  /// foram contadas: só se reconta o que mudou.
  int words;
  int wordsStamp;

  /// Os capítulos de uma parte (os capítulos não têm filhos na Etapa 1).
  final List<BookNode> children;

  bool get isPart => kind == BookNodeKind.part;

  Map<String, Object?> toJson() => {
        'id': id,
        'tipo': isPart ? 'parte' : 'capitulo',
        'titulo': title,
        if (file != null) 'arquivo': file,
        if (!isPart) 'status': status.name,
        if (label != null) 'rotulo': label,
        if (synopsis.isNotEmpty) 'sinopse': synopsis,
        if (!isPart) 'palavras': words,
        if (!isPart) 'palavrasEm': wordsStamp,
        if (isPart) 'filhos': [for (final c in children) c.toJson()],
      };

  static BookNode fromJson(Map<String, Object?> j) {
    final part = j['tipo'] == 'parte';
    return BookNode(
      id: j['id'] as String,
      kind: part ? BookNodeKind.part : BookNodeKind.chapter,
      title: j['titulo'] as String? ?? '',
      file: j['arquivo'] as String?,
      status: ChapterStatus.values.asNameMap()[j['status']] ?? ChapterStatus.draft,
      label: (j['rotulo'] as num?)?.toInt(),
      synopsis: j['sinopse'] as String? ?? '',
      words: (j['palavras'] as num?)?.toInt() ?? 0,
      wordsStamp: (j['palavrasEm'] as num?)?.toInt() ?? 0,
      children: [
        if (part)
          for (final c in (j['filhos'] as List<Object?>? ?? const [])) fromJson(c as Map<String, Object?>),
      ],
    );
  }
}

class Book {
  Book({required this.title, this.author = '', List<BookNode>? nodes}) : nodes = nodes ?? [];

  /// A versão do formato do `livro.json`. Um livro de versão maior (de um
  /// Quill mais novo) abre só para leitura no fichário.
  static const formatVersion = 1;

  String title;
  String author;

  /// A árvore, no primeiro nível: partes e capítulos fora de partes.
  final List<BookNode> nodes;

  /// Todos os capítulos, na ordem do livro.
  Iterable<BookNode> get chapters sync* {
    for (final n in nodes) {
      if (n.isPart) {
        yield* n.children;
      } else {
        yield n;
      }
    }
  }

  int get words => chapters.fold(0, (s, c) => s + c.words);

  /// O nó [id] e a lista em que ele está (a do livro ou a de uma parte).
  (BookNode, List<BookNode>)? find(String id) {
    for (final n in nodes) {
      if (n.id == id) return (n, nodes);
      for (final c in n.children) {
        if (c.id == id) return (c, n.children);
      }
    }
    return null;
  }

  /// A parte que tem [id]; null no primeiro nível.
  BookNode? parentOf(String id) {
    for (final n in nodes) {
      if (n.children.any((c) => c.id == id)) return n;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'formato': 'psito-quill-livro',
        'versao': formatVersion,
        'titulo': title,
        if (author.isNotEmpty) 'autor': author,
        'arvore': [for (final n in nodes) n.toJson()],
      };

  /// Lança [FormatException] se não é um `livro.json`.
  static Book fromJson(Map<String, Object?> j) {
    if (j['formato'] != 'psito-quill-livro') throw const FormatException('não é um livro do Quill');
    return Book(
      title: j['titulo'] as String? ?? '',
      author: j['autor'] as String? ?? '',
      nodes: [for (final n in (j['arvore'] as List<Object?>? ?? const [])) BookNode.fromJson(n as Map<String, Object?>)],
    );
  }
}
