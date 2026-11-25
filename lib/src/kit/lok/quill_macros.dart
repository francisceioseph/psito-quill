// As macros do Quill (D-090): uma biblioteca Basic no perfil do LibreOffice
// que é só do Quill, para o que a 24.2 só faz por uma janela do motor (que
// trava o LOK): o sumário, a tabela de figuras, o índice remissivo, a legenda,
// a referência a um título e ir a um marcador (o `.uno:JumpToMark` não vai).
//
// O `DisableMacrosExecution` do perfil (D-041) continua travando as macros
// dos documentos; as da biblioteca do perfil ("Minhas macros") rodam. O Quill
// regrava a biblioteca ao ligar: não edite o perfil à mão.
//
// Os argumentos vão no próprio endereço (`macro:///Lib.Módulo.Sub(args)`), que
// o Basic avalia como uma chamada, todos como texto (os sim e não são "1" e
// "0", para um `Integer`). Nada que a pessoa escreveu vai como texto
// ali: os textos vão em hexadecimal (`basicHex`, decodificado pelo `De`), e o
// resto são números e nomes que o Quill gera.
library;

/// O nome da biblioteca no perfil.
const quillMacroLibrary = 'PsitoQuill';

/// O módulo das referências.
const quillMacroModule = 'Referencias';

/// O endereço que o `postUnoCommand` despacha.
String quillMacro(String sub, [List<Object> args = const []]) {
  final parts = [
    for (final a in args)
      switch (a) {
        // Tudo entre aspas: na 24.2, um número sem aspas antes de um texto
        // entre aspas faz a chamada não acontecer; o Basic converte o texto.
        int() => '"$a"',
        bool() => a ? '"1"' : '"0"',
        MacroText(:final text) => '"${basicHex(text)}"',
        MacroName(:final name) => '"$name"',
        _ => throw ArgumentError.value(a, 'args', 'só int, bool, MacroText e MacroName'),
      },
  ];
  return 'macro:///$quillMacroLibrary.$quillMacroModule.$sub(${parts.join(',')})';
}

/// Um texto da pessoa (ou da tradução): vai em hexadecimal.
class MacroText {
  const MacroText(this.text);
  final String text;
}

/// Um nome que o Quill gera (a categoria, o nome do marcador de um título):
/// só letras sem acento, números e `_`.
class MacroName {
  MacroName(this.name) {
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(name)) throw ArgumentError.value(name, 'name');
  }
  final String name;
}

/// Cada unidade UTF-16 em 4 dígitos hexadecimais (o `Chr` do Basic volta;
/// o `ChrW` só existe no modo VBA).
String basicHex(String s) => [for (final u in s.codeUnits) u.toRadixString(16).padLeft(4, '0')].join();

/// O `script.xlb` da biblioteca.
const quillMacroLibraryXml = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE library:library PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "library.dtd">
<library:library xmlns:library="http://openoffice.org/2000/library" library:name="$quillMacroLibrary" library:readonly="false" library:passwordprotected="false">
 <library:element library:name="$quillMacroModule"/>
</library:library>
''';

/// O módulo, como o LibreOffice grava (`.xba`, o Basic escapado em XML).
String quillMacroModuleXml() => '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<!DOCTYPE script:module PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "module.dtd">\n'
    '<script:module xmlns:script="http://openoffice.org/2000/script" script:name="$quillMacroModule" script:language="StarBasic">'
    '${_xmlEscape(_basic)}</script:module>\n';

String _xmlEscape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

// O Basic. As constantes da API vão como números (o Basic não conhece os
// nomes sem o `com.sun.star...` inteiro): ReferenceFieldSource.BOOKMARK = 2,
// ControlCharacter.PARAGRAPH_BREAK = 0.
const _basic = r'''
REM Psito Quill: as referências (D-090). O Quill regrava este módulo ao ligar.
Option Explicit

Function De(h As String) As String
  Dim s As String, i As Long
  s = ""
  For i = 1 To Len(h) Step 4
    s = s & Chr(CLng("&H" & Mid(h, i, 4)))
  Next i
  De = s
End Function

Function Normal(s As String) As String
  Dim r As String
  r = Replace(Replace(Replace(s, Chr(9), " "), Chr(10), " "), Chr(13), " ")
  Do While InStr(r, "  ") > 0
    r = Replace(r, "  ", " ")
  Loop
  Normal = Trim(r)
End Function

REM Põe o índice no começo do parágrafo do cursor e o preenche.
Sub Inserir(idx As Object)
  Dim vc As Object, c As Object
  vc = ThisComponent.getCurrentController().getViewCursor()
  c = vc.getText().createTextCursorByRange(vc.getStart())
  vc.getText().insertTextContent(c, idx, False)
  idx.update()
End Sub

Sub Sumario(titulo As String, niveis As Integer)
  Dim idx As Object
  idx = ThisComponent.createInstance("com.sun.star.text.ContentIndex")
  idx.Title = De(titulo)
  idx.CreateFromOutline = True
  idx.Level = niveis
  Inserir(idx)
End Sub

Sub Figuras(titulo As String, categoria As String)
  Dim idx As Object
  idx = ThisComponent.createInstance("com.sun.star.text.IllustrationsIndex")
  idx.Title = De(titulo)
  idx.CreateFromLabels = True
  idx.LabelCategory = categoria
  Inserir(idx)
End Sub

Sub Remissivo(titulo As String)
  Dim idx As Object
  idx = ThisComponent.createInstance("com.sun.star.text.DocumentIndex")
  idx.Title = De(titulo)
  idx.UseAlphabeticalSeparators = True
  idx.UseCombinedEntries = True
  Inserir(idx)
End Sub

REM Todos os índices e os campos (o .uno:UpdateAllIndexes trava a edição
REM depois, numa aba aberta da 24.2).
Sub Atualizar()
  Dim all As Object, i As Long
  all = ThisComponent.getDocumentIndexes()
  For i = 0 To all.getCount() - 1
    all.getByIndex(i).update()
  Next i
  ThisComponent.getTextFields().refresh()
End Sub

Sub Marcar(r As Object)
  Dim m As Object
  m = ThisComponent.createInstance("com.sun.star.text.DocumentIndexMark")
  r.getText().insertTextContent(r, m, True)
End Sub

REM A seleção vira uma entrada do índice remissivo; com todas, cada
REM ocorrência da palavra (inteira, com as mesmas maiúsculas).
Sub MarcarEntrada(todas As Integer)
  Dim sel As Object, r As Object, d As Object, found As Object, i As Long
  sel = ThisComponent.getCurrentController().getSelection()
  If IsNull(sel) Then Exit Sub
  If Not sel.supportsService("com.sun.star.text.TextRanges") Then Exit Sub
  r = sel.getByIndex(0)
  If Trim(r.getString()) = "" Then Exit Sub
  If todas <> 0 Then
    d = ThisComponent.createSearchDescriptor()
    d.SearchString = r.getString()
    d.SearchCaseSensitive = True
    d.SearchWords = True
    found = ThisComponent.findAll(d)
    For i = 0 To found.getCount() - 1
      Marcar(found.getByIndex(i))
    Next i
  Else
    Marcar(r)
  End If
End Sub

REM A legenda num parágrafo novo, no estilo Legenda: depois do parágrafo da
REM imagem selecionada, ou depois da tabela do cursor: "Figura 1: " e o
REM cursor no fim. O número é o campo de sequência do .uno:InsertField, que
REM o motor calcula (o da API fica sem número), pelo nome que a interface
REM do motor mostra (sequencia: "Figura", "Tabela"; o motor abre tudo em
REM pt-BR); por esse nome, ele entra na sequência que o LibreOffice já tem.
Sub Legenda(rotulo As String, sequencia As String)
  Dim doc As Object, ctl As Object, sel As Object, vc As Object
  Dim a As Object, t As Object, c As Object, n As Object, en As Object, el As Object
  Dim depois As Boolean, imagem As Boolean, a2(3) As New com.sun.star.beans.PropertyValue
  doc = ThisComponent
  ctl = doc.getCurrentController()
  sel = ctl.getSelection()
  vc = ctl.getViewCursor()
  If Not IsNull(sel) Then
    If sel.supportsService("com.sun.star.text.TextContent") And Not sel.supportsService("com.sun.star.text.TextRanges") Then
      a = sel.getAnchor()
    ElseIf sel.supportsService("com.sun.star.drawing.ShapeCollection") Then
      a = sel.getByIndex(0).getAnchor()
    End If
  End If
  imagem = Not (IsNull(a) Or IsEmpty(a))
  If Not imagem Then
    REM A tabela do cursor: um parágrafo vazio antes do que vem depois dela.
    If IsEmpty(vc.TextTable) Then Exit Sub
    t = vc.TextTable
    en = doc.getText().createEnumeration()
    depois = False
    Do While en.hasMoreElements()
      el = en.nextElement()
      If depois Then
        c = el.getText().createTextCursorByRange(el.getStart())
        el.getText().insertControlCharacter(c, 0, False)
        c.gotoPreviousParagraph(False)
        Exit Do
      End If
      If el.supportsService("com.sun.star.text.TextTable") Then depois = EqualUnoObjects(el, t)
    Loop
    If IsNull(c) Then Exit Sub
  Else
    REM Depois do parágrafo da imagem, sem partir ele nem apagar nada:
    REM partir no fim de um parágrafo vazio levaria a âncora (e um marcador
    REM no mesmo ponto) para o parágrafo novo. Com um parágrafo depois, um
    REM vazio antes dele; no fim do texto, um acrescentado.
    c = a.getText().createTextCursorByRange(a.getStart())
    c.gotoEndOfParagraph(False)
    n = c.getText().createTextCursorByRange(c)
    If n.gotoNextParagraph(False) And IsEmpty(n.TextTable) = IsEmpty(c.TextTable) Then
      n.getText().insertControlCharacter(n, 0, False)
      n.gotoPreviousParagraph(False)
      c = n
    ElseIf Not n.gotoNextParagraph(False) Then
      c.getText().finishParagraph(Array())
      c = c.getText().createTextCursorByRange(c.getText().getEnd())
    Else
      REM Uma tabela logo depois: parte no fim do parágrafo da imagem.
      c.getText().insertControlCharacter(c, 0, False)
    End If
  End If
  c.ParaStyleName = "Caption"
  c.getText().insertString(c, De(rotulo) & " ", False)
  REM Com a imagem selecionada, o cursor de vista não vai a um trecho: a
  REM seleção nova (o cursor no fim da legenda) tira a da imagem. O motor
  REM troca para o modo de texto num temporizador (uns 150 ms na sonda):
  REM sem o Wait, o campo não entra.
  ctl.select(c)
  If imagem Then Wait 500
  a2(0).Name = "Type" : a2(0).Value = CInt(23)
  a2(1).Name = "Name" : a2(1).Value = sequencia
  a2(2).Name = "Content" : a2(2).Value = sequencia & "+1"
  a2(3).Name = "Format" : a2(3).Value = CLng(4)
  createUnoService("com.sun.star.frame.DispatchHelper").executeDispatch(ctl.getFrame(), ".uno:InsertField", "", 0, a2())
  vc.getText().insertString(vc, ": ", False)
End Sub

REM O marcador de referência do título (um __RefHeading__, como o do
REM LibreOffice): o que ele já tem, ou um novo com o nome.
Function MarcaDoTitulo(p As Object, nova As String) As String
  Dim doc As Object, en As Object, por As Object, b As Object, c As Object, nome As String
  doc = ThisComponent
  REM Os __RefHeading__ não entram no getBookmarks(): pelas porções do
  REM parágrafo. A 24.2 aceita um só por título.
  en = p.createEnumeration()
  Do While en.hasMoreElements()
    por = en.nextElement()
    If por.TextPortionType = "Bookmark" Then
      nome = por.Bookmark.getName()
      If Left(nome, 14) = "__RefHeading__" Then
        MarcaDoTitulo = nome
        Exit Function
      End If
    End If
  Loop
  b = doc.createInstance("com.sun.star.text.Bookmark")
  b.setName(nova)
  c = p.getText().createTextCursorByRange(p.getStart())
  c.gotoEndOfParagraph(True)
  p.getText().insertTextContent(c, b, True)
  MarcaDoTitulo = nova
End Function

REM A referência ao título número indice (na ordem do texto, sem os
REM vazios), conferida pelo texto: se não bate, o primeiro com o texto.
Sub RefTitulo(indice As Long, texto As String, nova As String, parte As Integer)
  Dim doc As Object, en As Object, el As Object, alvo As Object, f As Object, vc As Object
  Dim quer As String, n As Long, porTexto As Object, noIndice As Object
  doc = ThisComponent
  quer = Normal(De(texto))
  en = doc.getText().createEnumeration()
  n = 0
  Do While en.hasMoreElements()
    el = en.nextElement()
    If el.supportsService("com.sun.star.text.Paragraph") Then
      If el.OutlineLevel > 0 And Normal(el.getString()) <> "" Then
        If n = indice Then noIndice = el
        If IsNull(porTexto) Or IsEmpty(porTexto) Then
          If Normal(el.getString()) = quer Then porTexto = el
        End If
        n = n + 1
      End If
    End If
  Loop
  If Not (IsNull(noIndice) Or IsEmpty(noIndice)) Then
    If Normal(noIndice.getString()) = quer Then alvo = noIndice
  End If
  If IsNull(alvo) Or IsEmpty(alvo) Then alvo = porTexto
  If IsNull(alvo) Or IsEmpty(alvo) Then alvo = noIndice
  If IsNull(alvo) Or IsEmpty(alvo) Then Exit Sub
  f = doc.createInstance("com.sun.star.text.textfield.GetReference")
  f.ReferenceFieldSource = 2
  f.SourceName = MarcaDoTitulo(alvo, nova)
  f.ReferenceFieldPart = parte
  vc = doc.getCurrentController().getViewCursor()
  vc.getText().insertTextContent(vc, f, True)
  doc.getTextFields().refresh()
End Sub

Sub IrMarcador(nome As String)
  Dim bms As Object
  bms = ThisComponent.getBookmarks()
  If Not bms.hasByName(De(nome)) Then Exit Sub
  ThisComponent.getCurrentController().getViewCursor().gotoRange(bms.getByName(De(nome)).getAnchor(), False)
End Sub

REM O parágrafo e as propriedades do documento (D-091). Um cursor de texto
REM sobre a seleção: as propriedades valem para cada parágrafo dela.
Function Trecho() As Object
  Dim vc As Object
  vc = ThisComponent.getCurrentController().getViewCursor()
  Trecho = vc.getText().createTextCursorByRange(vc)
End Function

REM Não adicionar intervalo entre parágrafos do mesmo estilo.
Sub Intervalo(liga As Integer)
  Trecho().ParaContextMargin = (liga = 1)
End Sub

REM Os lados (1 em cima, 2 embaixo, 4 à esquerda, 8 à direita), a largura e
REM a distância do texto em 1/100 mm, a cor em RGB. Só o BorderLine2 com o
REM LineWidth vale na 24.2, e os nomes são os sem "Para" (TopBorder...).
Sub Bordas(lados As Integer, largura As Long, cor As Long, distancia As Long)
  Dim c As Object
  Dim b As New com.sun.star.table.BorderLine2
  Dim n As New com.sun.star.table.BorderLine2
  c = Trecho()
  b.Color = cor
  b.LineWidth = largura
  b.LineStyle = 0
  If (lados And 1) <> 0 Then c.TopBorder = b Else c.TopBorder = n
  If (lados And 2) <> 0 Then c.BottomBorder = b Else c.BottomBorder = n
  If (lados And 4) <> 0 Then c.LeftBorder = b Else c.LeftBorder = n
  If (lados And 8) <> 0 Then c.RightBorder = b Else c.RightBorder = n
  If lados = 0 Then c.BorderDistance = 0 Else c.BorderDistance = distancia
End Sub

REM As tabulações: "n_posição_alinhamento_preenchimento_..." (a posição em
REM 1/100 mm; o alinhamento do TabAlign; o preenchimento, o código do
REM caractere). Com n = 0, voltam as do estilo.
Sub Tabulacoes(spec As String)
  Dim c As Object, p As Variant, n As Integer, i As Integer
  c = Trecho()
  p = Split(spec, "_")
  n = CInt(p(0))
  If n = 0 Then
    c.setPropertyToDefault("ParaTabStops")
    Exit Sub
  End If
  Dim t(n - 1) As New com.sun.star.style.TabStop
  For i = 0 To n - 1
    t(i).Position = CLng(p(1 + 3 * i))
    t(i).Alignment = CInt(p(2 + 3 * i))
    t(i).FillChar = CInt(p(3 + 3 * i))
    t(i).DecimalChar = 44
  Next i
  c.ParaTabStops = t()
End Sub

REM As etiquetas vêm separadas por quebras de linha.
Sub Propriedades(titulo As String, assunto As String, autor As String, etiquetas As String, comentario As String)
  Dim p As Object, k As String, vazio() As String
  p = ThisComponent.getDocumentProperties()
  p.Title = De(titulo)
  p.Subject = De(assunto)
  p.Author = De(autor)
  p.Description = De(comentario)
  k = De(etiquetas)
  If k = "" Then p.Keywords = vazio() Else p.Keywords = Split(k, Chr(10))
  ThisComponent.setModified(True)
End Sub

REM O Layout e o Inserir (D-092). Os números de linha, de 5 em 5 como no
REM Word, ligados ou não.
Sub Linhas(liga As Integer)
  Dim n As Object
  n = ThisComponent.getLineNumberingProperties()
  n.IsOn = (liga = 1)
  n.Interval = 5
  n.CountEmptyLines = False
End Sub

REM A cor do estilo de página do cursor; -1 tira. O .uno:FillPageColor da
REM 24.2 ignora a cor (põe a azul padrão).
Sub CorPagina(cor As Long)
  Dim vc As Object, ps As Object
  vc = ThisComponent.getCurrentController().getViewCursor()
  ps = ThisComponent.getStyleFamilies().getByName("PageStyles").getByName(vc.PageStyleName)
  If cor < 0 Then
    ps.FillStyle = com.sun.star.drawing.FillStyle.NONE
  Else
    ps.FillStyle = com.sun.star.drawing.FillStyle.SOLID
    ps.FillColor = cor
  End If
  ThisComponent.setModified(True)
End Sub

REM Uma caixa de texto no parágrafo do cursor, com a largura em 1/100 mm; o
REM cursor vai para dentro dela.
Sub Caixa(largura As Long)
  Dim vc As Object, f As Object
  Dim sz As New com.sun.star.awt.Size
  vc = ThisComponent.getCurrentController().getViewCursor()
  f = ThisComponent.createInstance("com.sun.star.text.TextFrame")
  sz.Width = largura
  sz.Height = 1000
  f.Size = sz
  f.AnchorType = com.sun.star.text.TextContentAnchorType.AT_PARAGRAPH
  vc.getText().insertTextContent(vc, f, False)
  vc.gotoRange(f.getText().getStart(), False)
End Sub

''';
