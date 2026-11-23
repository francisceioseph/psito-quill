# Fase 2B: a nova interface

O plano está no `docs/PLANO.md` (seção 10). Cada etapa tem um documento aqui: o que entrou, como funciona, onde está no código, o que foi medido e o que fica para o Francisco conferir à mão. As decisões ficam no `docs/DECISOES.md` (a partir do D-041).

| Etapa | Documento | Estado |
|---|---|---|
| 0. Privacidade e linha de base | [etapa-0-privacidade.md](etapa-0-privacidade.md) | feita, medida |
| 1. A fundação Material 3 | [etapa-1-material3.md](etapa-1-material3.md) | feita, medida |
| 2. A casca do editor | [etapa-2-casca.md](etapa-2-casca.md) | feita |
| 3. As prévias de fontes e estilos | [etapa-3-previas.md](etapa-3-previas.md) | feita |
| 4. A régua | [etapa-4-regua.md](etapa-4-regua.md) | feita (sem criar tabulações) |
| 5. Várias páginas e a Estrutura | [etapa-5-paginas.md](etapa-5-paginas.md) | feita |
| 6. O modo zen | [etapa-6-zen.md](etapa-6-zen.md) | feita |
| 7. A interface que respira | [etapa-7-espaco.md](etapa-7-espaco.md) | feita |
| 8. Ocupado sem janelas | [etapa-8-ocupado.md](etapa-8-ocupado.md) | feita |
| 9. Acessibilidade | [etapa-9-acessibilidade.md](etapa-9-acessibilidade.md) | feita |

## Como medir a memória de uma etapa

A memória absoluta muda uns 20 MB de um dia para outro (D-038). Por isso cada etapa é medida **no mesmo dia, lado a lado** com a build da etapa anterior:

```bash
tool/ab.py <commit-anterior>
```

O `tool/ab.py` monta o commit anterior numa `git worktree` temporária, faz a build de release das duas, e roda o `tool/mapas.py` três vezes em cada uma, alternando. Imprime a mediana da memória anônima e do RSS por etapa do bench.

## Onde parou (23/11/2026)

- Etapas 0 a 5 feitas, com `./test.sh --integracao` verde. Medidas: 0, 1 e 2 dentro do orçamento; a 3+4 mostrou o heap crescendo ~14 MB com a régua (números medidos a cada quadro), corrigido com o cache `RulerLabels` e com a régua horizontal sem repintar na rolagem vertical. Depois da correção, as Etapas 3–5 juntas contra a Fase 2: anônima +2,9 MB com o capítulo e +1,7 MB depois de digitar (antes da correção, +18,5). O RSS sobe ~10 MB, quase todo de arquivo (fontes +2,5 e libmergedlo +3,2, que o kernel devolve). Rolar 59,6 fps; tecla → ladrilho p95 9,4 ms.
- Etapa 6 (zen): feita (D-048), com os testes de widget. A medida saiu junto com o começo da Etapa 7 (ver o `etapa-6-zen.md`).
- Etapa 7 (nova, D-049): o Francisco testou o app e achou os comandos densos, mal distribuídos e difíceis de clicar, sem aproveitar as telas grandes, e os menus pobres. Ela vem antes de "ocupado" e "acessibilidade", que viraram 8 e 9.
- Etapa 7: feita (D-049 a D-065), com `./test.sh --integracao` verde. O Esc no menu de contexto foi corrigido pela integração (o foco fica no menu enquanto ele está aberto).
- Etapas 8 e 9: feitas (D-066, D-067), com `./test.sh --integracao` verde.
- O fecho: feito (`docs/FASE2B-RESULTADOS.md`). A pendência maior é abrir o capítulo, que ficou em 854 ms (a Fase 2 abria em 369).
