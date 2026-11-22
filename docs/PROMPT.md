# Prompt para começar o Psito Quill

Cole numa sessão nova, aberta em `~/projects/psito-quill` (a pasta já existe, só com estes documentos em `docs/`).

---

Vamos começar o **Psito Quill**: um editor de texto para eu escrever livros longos (*Dustland*, *Silicon Gods*).
- **O motor** é o LibreOffice pelo LibreOfficeKit do sistema.
- **A interface** é em Flutter, com um design system próprio e temas (Claro, Escuro, Sépia, Clássico 97 com menus e Alto contraste).
- **Os plugins** são em Lua 5.4, numa caixa de areia.
- **Ele precisa gastar pouca memória**, não crescer em sessões longas e nunca travar a digitação.

O plano completo está em `docs/PLANO.md`. Leia inteiro antes de qualquer coisa. Ele tem as decisões, a arquitetura, a interface, o modo Livro, a API Lua, as metas de memória, os testes e as fases.

**O que fazer agora: só a Fase 0** (a prova do motor, seção 10 do plano).
1. Transforme esta pasta no projeto com o `flutter create .` (Linux, com a última versão estável do Flutter, sem apagar o `docs/`). Crie também o `CLAUDE.md`, o `docs/ARCHITECTURE.md` (a tabela de padrões e a pirâmide de testes) e o `docs/DECISOES.md`.
2. Escreva o plugin nativo em C++:
   - o `lok_init` com o LibreOffice do sistema, numa thread própria com uma fila;
   - os ladrilhos para uma `FlPixelBufferTexture`;
   - os callbacks para o Dart por `NativeCallable.listener`;
   - os bindings do `LibreOfficeKit.h` gerados com o `ffigen`.
3. Uma tela mínima que abre um DOCX de 30 páginas, rola, deixa digitar, aplica negrito e salva.
4. Lua 5.4 embutido rodando um "olá", com o teto de memória e a interrupção por instruções testados.
5. Meça, com os números no `docs/FASE0-RESULTADOS.md`:
   - a memória (RSS) com o documento vazio e com as 30 páginas;
   - a latência tecla → ladrilho (p50 e p95);
   - a nitidez a 1x e 1,25x;
   - se o papel escuro (`.uno:ChangeTheme`) funciona na versão instalada.
6. Diga se passou no critério de parada da seção 10. Se não passou, pare e me mostre os números antes de seguir.

**Regras de trabalho:**
- **Padrões conhecidos**, dizendo qual e por quê. Pense criticamente antes de cada parte.
- **Atomic design** com tokens desde o primeiro widget: nenhuma cor literal nos widgets.
- **A pirâmide de testes**, com a contagem por nível no fim. O host tem pouca RAM: limite os processos de teste, como no `./test.sh` do Psito Player.
- **Toda decisão nova vai no `docs/DECISOES.md`.**
- **O Quill não conhece o Psito OS.** Não mexa no `psito-os` sem minha autorização.
- **Commit e push só quando eu pedir.** Os commits terminam com o `Co-Authored-By` do Claude.
- **Na dúvida sobre o produto, pergunte.** As perguntas abertas estão na seção 12 do plano.
