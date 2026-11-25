# Psito Quill

Um editor de texto para escrever livros longos. O motor é o LibreOffice (pelo LibreOfficeKit do sistema), a interface é em Flutter, e os plugins são em Lua 5.4.

Em construção. A Fase 4 (compilar e revisar) começou pelo compilar: o livro inteiro em PDF (com o sumário e os marcadores), EPUB, DOCX ou ODT, com a folha de rosto e as partes (D-086), e os modelos Manuscrito, Livro 6×9 e E-book, mais os de quem escreve (D-087). A revisão tem os comentários (o painel, as respostas, o resolvido e a contagem no fichário, D-088) e o controle de alterações, com os modos Editando, Revisão e Leitura (D-089). As referências têm o sumário no capítulo, as legendas, os índices de figuras e de tabelas, os marcadores, a referência cruzada e o índice remissivo, também no compilar (D-090). A Estrutura ganhou o "Início do documento", o nível e recolher; o parágrafo, a cor de fundo, as bordas, as tabulações e o intervalo entre parágrafos do mesmo estilo; e as Informações, as contagens e as propriedades editáveis (D-091). A Fase 3 (o modo Livro: a pasta `.psitobook` com um ODT por capítulo, o importador de DOCX, o fichário, o salvamento automático, a página do livro, o PDF e a impressão, as cenas, a busca no livro, os instantâneos, as notas, as metas e a cortiça) está em `docs/FASE3-RESULTADOS.md`. A Fase 2B (a interface nova: Material 3, a faixa que se adapta à largura, os trilhos, a régua, várias páginas, a Estrutura, o modo zen, as abas de documentos, os bastidores, o progresso sem janelas e a acessibilidade) está em `docs/FASE2B-RESULTADOS.md`. A Fase 2 (estilos, o painel Formatar, localizar e substituir, ortografia, tabelas, imagens, página, a paleta de comandos e o tema Clássico 97) está em `docs/FASE2-RESULTADOS.md`. A Fase 1 (o editor básico: digitar com acentos, desfazer, copiar e colar, a faixa Início, abrir e salvar ODT e DOCX, os recentes) está em `docs/FASE1-RESULTADOS.md`; a prova do motor, em `docs/FASE0-RESULTADOS.md`; o plano completo, em `docs/PLANO.md`.

## Para instalar

Os pacotes de cada versão estão nas [releases](https://github.com/francisceioseph/psito-quill/releases). O Quill usa o LibreOffice Writer do sistema (24.2 ou mais novo), que o gerenciador de pacotes instala junto.

```bash
sudo apt install ./psito-quill_*_amd64.deb      # Ubuntu 24.04 ou mais novo, Debian 13
sudo dnf install ./psito-quill-*.x86_64.rpm     # Fedora
```

## Para compilar (Ubuntu 24.04)

```bash
sudo apt install libreoffice-writer libreofficekit-dev liblua5.4-dev libgtest-dev libclang-18-dev
flutter build linux --release
build/linux/x64/release/bundle/psito-quill capitulo.docx
```

## Testes

```bash
./test.sh               # unidade, widget e nativo
./test.sh --integracao  # e com o LibreOffice real (abre uma janela)
tool/bench.sh           # as medições de memória e latência
```

## Acessibilidade

Temas de alto contraste, o tamanho da interface até 200 %, botões maiores, o cursor mais grosso e sem piscar, e reduzir movimento ficam em Arquivo › Preferências › Acessibilidade. Para o leitor de tela, o Quill expõe o parágrafo onde está o cursor (o motor desenha a página como imagem, e não dá o documento inteiro): o leitor lê o parágrafo e acompanha o cursor dentro dele.

## Licença

[Mozilla Public License 2.0](LICENSE), a mesma do LibreOffice. Os arquivos do Quill continuam abertos em qualquer versão modificada; quem usa o Quill junto com outro código não precisa abrir o resto.
