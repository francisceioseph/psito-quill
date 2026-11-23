# Etapa 0: privacidade e linha de base

**Pedido:** "tudo precisa ser muito privado, sem logs, sem telemetria. Tudo no computador do cliente." A decisão é o D-041.

## O que entrou

| O quê | Onde |
|---|---|
| As travas de privacidade no perfil do LibreOffice | `lib/src/kit/lok/lo_profile.dart` (`LoProfile.privacy`, `ensureSettings`) |
| Os avisos do LibreOffice fora do terminal (`SAL_LOG=-WARN-INFO`) | `packages/psito_quill_kit/linux/core/lok_engine.cc` (`LokEngine::init`) |
| A preferência "Guardar a lista de arquivos recentes" | `lib/src/settings/settings.dart` (`keepRecents`), `lib/src/files/recent_files.dart` (`keep`), `lib/src/ui/organisms/file_panel.dart` |
| A ferramenta de medição lado a lado | `tool/ab.py` (usa o `tool/mapas.py`) |
| Os testes | `test/unit/privacy_test.dart` |

## Como funciona

**O perfil.** O `LoProfile.ensureSettings` roda antes de o motor ligar e grava, no `registrymodifications.xcu` do perfil do Quill, os esquemas de cor do papel e as travas da tabela do D-041: sem relatório de falha, sem buscar imagens e links de fora, sem macros, sem lista de recentes nem miniaturas do motor. Tudo fica entre os comentários `<!-- psito-quill: esquemas -->`. Ao sair, o LibreOffice regrava o arquivo sem os comentários; na próxima vez o Quill tira as suas linhas pelo texto exato e grava de novo, sem duplicar.

**Os avisos.** O LibreOffice escreve avisos no terminal (o `SAL_WARN`). Não é um arquivo, mas é texto do motor que pode ter caminhos de arquivo. O `LokEngine::init` define `SAL_LOG=-WARN-INFO` com `setenv(..., 0)`: quem depura define a variável antes e ela vale.

**Os recentes.** `RecentFiles(store, keep: false)` não lê o arquivo, apaga o que havia e guarda a lista só na memória. Trocar `keep` para `true` grava a lista da sessão; para `false`, apaga o arquivo. O `main.dart` liga a preferência ao `RecentFiles` com um `addListener`.

## O que os testes conferem

- As seis travas estão no perfil gerado, e não duplicam quando o LibreOffice regrava o arquivo.
- Os recentes desligados não gravam e apagam o arquivo; religar grava; a preferência é guardada.
- Nenhum arquivo de `lib/` usa `HttpClient`, `Socket`, `WebSocket`, `package:http` ou `HttpServer`.
- O núcleo nativo (fora das ferramentas de medição em `linux/tools`) não abre socket, não usa curl e não grava arquivo (`fopen` com `w` ou `a`, `ofstream`).

## Medida

A memória, lado a lado com a Fase 2 (`ac8a2d6`), pelo `tool/ab.py`: veja a seção "Resultado" abaixo.

## Para o Francisco conferir

- Em Arquivo › Preferências › Privacidade, desligar "Guardar a lista de arquivos recentes": a lista some do disco (`~/.config/psito-quill/recentes.json`), mas continua na sessão.

## Resultado

`tool/ab.py ac8a2d6`, 23/11/2026, mediana de 3 rodadas alternadas (MB):

| Etapa do bench | Anônima Fase 2 | Anônima Etapa 0 | Δ | RSS Fase 2 | RSS Etapa 0 |
|---|---|---|---|---|---|
| Motor ligado | 108,2 | 108,4 | +0,1 | 259,0 | 258,9 |
| Vazio | 181,4 | 174,0 | −7,5 | 367,8 | 370,3 |
| Capítulo de 30 páginas | 230,5 | 229,0 | −1,5 | 431,4 | 429,7 |
| Depois de digitar | 247,6 | 245,9 | −1,7 | 452,3 | 448,0 |

Abrir: 356 → 358 ms. Rolar: 59,7 fps nos dois. Tecla → ladrilho p95: 9,3 ms nos dois. Nada cresceu; a queda no "vazio" está dentro do ruído dessa etapa (o motor ainda está carregando). Os testes: `./test.sh --integracao` verde.
