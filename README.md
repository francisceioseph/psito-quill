# Psito Quill

Um editor de texto para escrever livros longos. O motor é o LibreOffice (pelo LibreOfficeKit do sistema), a interface é em Flutter, e os plugins são em Lua 5.4.

Em construção. A Fase 4 (compilar e revisar, em `docs/FASE4-RESULTADOS.md`) trouxe o compilar: o livro inteiro em PDF (com o sumário e os marcadores), EPUB, DOCX ou ODT, com a folha de rosto e as partes (D-086), e os modelos Manuscrito, Livro 6×9 e E-book, mais os de quem escreve (D-087). A revisão tem os comentários (o painel, as respostas, o resolvido e a contagem no fichário, D-088) e o controle de alterações, com os modos Editando, Revisão e Leitura (D-089). As referências têm o sumário no capítulo, as legendas, os índices de figuras e de tabelas, os marcadores, a referência cruzada e o índice remissivo, também no compilar (D-090). A Estrutura ganhou o "Início do documento", o nível e recolher; o parágrafo, a cor de fundo, as bordas, as tabulações e o intervalo entre parágrafos do mesmo estilo; e as Informações, as contagens e as propriedades editáveis (D-091). A Página Inicial ganhou o pincel, o Aa e as listas de vários níveis; o Layout, as colunas, os números de linha, a cor da página, a marca d'água e a ordem das imagens; e o Inserir, a caixa de texto (D-092). As Preferências ganharam as regras da ortografia, o acesso rápido e o atalho de cada comando, e há os modelos: "Salvar como modelo", o `estilos.ott` do livro e "Novo a partir do modelo" (D-093). O Quill se instala por um repositório APT ou DNF assinado, que se atualiza junto com o sistema. A Fase 3 (o modo Livro: a pasta `.psitobook` com um ODT por capítulo, o importador de DOCX, o fichário, o salvamento automático, a página do livro, o PDF e a impressão, as cenas, a busca no livro, os instantâneos, as notas, as metas e a cortiça) está em `docs/FASE3-RESULTADOS.md`. A Fase 2B (a interface nova: Material 3, a faixa que se adapta à largura, os trilhos, a régua, várias páginas, a Estrutura, o modo zen, as abas de documentos, os bastidores, o progresso sem janelas e a acessibilidade) está em `docs/FASE2B-RESULTADOS.md`. A Fase 2 (estilos, o painel Formatar, localizar e substituir, ortografia, tabelas, imagens, página, a paleta de comandos e o tema Clássico 97) está em `docs/FASE2-RESULTADOS.md`. A Fase 1 (o editor básico: digitar com acentos, desfazer, copiar e colar, a faixa Início, abrir e salvar ODT e DOCX, os recentes) está em `docs/FASE1-RESULTADOS.md`; a prova do motor, em `docs/FASE0-RESULTADOS.md`; o plano completo, em `docs/PLANO.md`.

## Para instalar

O Quill usa o LibreOffice Writer do sistema (24.2 ou mais novo), que o gerenciador de pacotes instala junto.

### Pelo repositório APT

No Ubuntu 24.04 ou mais novo, no Debian 13 ou no Mint 22. Ele se atualiza junto com o sistema:

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://francisceioseph.github.io/psito-quill/psito-quill.asc | sudo tee /etc/apt/keyrings/psito-quill.asc >/dev/null
printf 'Types: deb\nURIs: https://francisceioseph.github.io/psito-quill\nSuites: stable\nComponents: main\nArchitectures: amd64\nSigned-By: /etc/apt/keyrings/psito-quill.asc\n' | sudo tee /etc/apt/sources.list.d/psito-quill.sources >/dev/null
sudo apt update
sudo apt install psito-quill
```

### Pelo repositório DNF

No Fedora, em x86_64. Ele se atualiza junto com o sistema, e a primeira instalação pede para aceitar a chave:

```bash
sudo curl -fsSL -o /etc/yum.repos.d/psito-quill.repo https://francisceioseph.github.io/psito-quill/psito-quill.repo
sudo dnf install psito-quill
```

### Pelo pacote

Os pacotes de cada versão também estão nas [releases](https://github.com/francisceioseph/psito-quill/releases):

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

## Créditos

Os sons das teclas da máquina de escrever são cortes da gravação ["Typewriter 170428_1482.wav"](https://freesound.org/people/megashroom/sounds/390343/), de megashroom, uma Smith Corona Corsair, em domínio público (CC0). Os detalhes estão em `assets/sons/LEIA-ME.md`.

## Licença

[Mozilla Public License 2.0](LICENSE), a mesma do LibreOffice. Os arquivos do Quill continuam abertos em qualquer versão modificada; quem usa o Quill junto com outro código não precisa abrir o resto.
