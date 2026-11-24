// API C do psito_quill_kit, chamada pelo Dart por dart:ffi.
//
// Os bindings Dart deste arquivo (e dos enums do LibreOfficeKitEnums.h) são
// gerados pelo ffigen: `dart run ffigen` em packages/psito_quill_kit.
//
// Regras:
// - Tudo é assíncrono: as funções só põem uma tarefa na fila do kit e voltam.
//   Os resultados chegam pelo pqk_event_fn, de qualquer thread (no Dart, um
//   NativeCallable.listener devolve na thread da UI).
// - O payload de cada evento é alocado aqui e fica com o Dart, que o devolve
//   com pqk_free_string depois de ler.
// - O Dart nunca chama o LibreOfficeKit direto: o LOK não é thread-safe, e só
//   a thread do kit fala com ele.
#ifndef PSITO_QUILL_KIT_API_H_
#define PSITO_QUILL_KIT_API_H_

#include <stdbool.h>
#include <stdint.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define PQK_EXPORT __attribute__((visibility("default")))
#else
#define PQK_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Eventos próprios do kit. Os do LOK (LOK_CALLBACK_*) chegam com o número
// original, abaixo de 10000.
enum PqkEvent {
  PQK_EVENT_READY = 10000,         // payload: versão do LibreOffice (JSON)
  PQK_EVENT_INIT_FAILED = 10001,
  PQK_EVENT_OPENED = 10002,        // payload: {"id":n,"width":tw,"height":tw,"parts":n}
  PQK_EVENT_OPEN_FAILED = 10003,
  PQK_EVENT_TILE = 10004,          // payload: "vaga,coluna,linha,escalaMilli"
  PQK_EVENT_SAVED = 10005,
  PQK_EVENT_SAVE_FAILED = 10006,
  PQK_EVENT_CLOSED = 10007,        // payload: o número do documento
  PQK_EVENT_COMMAND_VALUES = 10008, // payload: "comando\n" + JSON
  PQK_EVENT_TEXT_SELECTION = 10009, // payload: "mime\n" + texto
  PQK_EVENT_ACTIVATED = 10010,     // payload: {"id":n,"width":tw,"height":tw,"parts":n}
  PQK_EVENT_CONVERTED = 10011,     // payload: {"id":n,"ok":bool,"error":"..."}
  PQK_EVENT_PRINTED = 10012,       // payload: "ok", "cancelado" ou "erro\n<mensagem>"
  PQK_EVENT_LUA_LOG = 10100,
  PQK_EVENT_LUA_DONE = 10101,      // payload: {"ok":true} ou {"ok":false,"error":"..."}
};

typedef void (*pqk_event_fn)(int32_t type, char* payload);

// Liga o motor. `tile_slots` vagas de 256×256 (256 KB cada) viram texturas.
// Devolve 0 se começou (o fim chega como READY ou INIT_FAILED).
PQK_EXPORT int32_t pqk_init(const char* install_path, const char* profile_url,
                            int32_t tile_slots, pqk_event_fn on_event);
PQK_EXPORT void pqk_shutdown(void);

// Id da textura do Flutter da vaga, ou -1.
PQK_EXPORT int64_t pqk_tile_texture_id(int32_t slot);
PQK_EXPORT int32_t pqk_tile_slots(void);
PQK_EXPORT int32_t pqk_tile_size(void);

// Vários documentos abertos, um ativo (D-054); as outras chamadas vão ao ativo.
// pqk_open abre mais um e o ativa ("" ou NULL: um documento vazio).
PQK_EXPORT void pqk_open(const char* path);
// Troca o ativo pelo número que veio no OPENED.
PQK_EXPORT void pqk_activate(int32_t id);
// Fecha o ativo, ou um pelo número.
PQK_EXPORT void pqk_close(void);
PQK_EXPORT void pqk_close_document(int32_t id);
// Área visível em twips, e a escala (pixels físicos por pixel lógico × zoom) × 1000.
PQK_EXPORT void pqk_set_viewport(int32_t scale_milli, int64_t x, int64_t y, int64_t w,
                                 int64_t h);
PQK_EXPORT void pqk_repaint_all(void);
// O papel escuro (D-074): com `on`, cada ladrilho tem a luminosidade
// invertida, com o tom mantido. O papel claro do motor (`src_paper`, 0xRRGGBB)
// vira `paper`, e o preto vira `ink`. Vale para os ladrilhos pintados depois:
// chame o pqk_repaint_all em seguida.
// Imprimir (D-076): a janela de impressão do GTK, e o PDF [pdf_path] vai à
// impressora escolhida. Volta logo; a resposta vem em PQK_EVENT_PRINTED, e o
// arquivo é apagado no fim (ele tem o texto do livro).
PQK_EXPORT void pqk_print_pdf(const char* pdf_path, const char* title);
PQK_EXPORT void pqk_set_paper_invert(bool on, uint32_t paper, uint32_t ink, uint32_t src_paper);
// Os callbacks de acessibilidade do documento ativo (o parágrafo e o cursor).
PQK_EXPORT void pqk_set_accessibility(bool on);
// Abre o documento em [path] oculto, para carregar o dicionário antes do
// primeiro capítulo (D-069). Só sem documento aberto; apaga o arquivo.
PQK_EXPORT void pqk_preload_spelling(const char* path);
// Define as variáveis de ambiente do LibreOffice. Chame no começo do main,
// antes de qualquer thread: o setenv com outra thread lendo o ambiente
// derruba o processo (D-072).
PQK_EXPORT void pqk_prepare_environment(void);
// Abre [src] oculto ("" para um documento novo), salva em [dst] no [format]
// ("odt", "fodt") e fecha, sem tocar nas abas. Responde PQK_EVENT_CONVERTED.
PQK_EXPORT void pqk_convert(int32_t id, const char* src, const char* dst, const char* format);
PQK_EXPORT void pqk_post_key(int32_t type, int32_t char_code, int32_t key_code);
PQK_EXPORT void pqk_post_mouse(int32_t type, int32_t x, int32_t y, int32_t count,
                               int32_t buttons, int32_t modifier);
PQK_EXPORT void pqk_uno(const char* command, const char* args_json);
PQK_EXPORT void pqk_save_as(const char* path, const char* format, const char* options);
PQK_EXPORT void pqk_command_values(const char* command);
// Arrasta a alça (ou o corpo) da imagem selecionada. type:
// LOK_SETGRAPHICSELECTION_START no ponto de partida, _END no de chegada.
PQK_EXPORT void pqk_set_graphic_selection(int32_t type, int32_t x, int32_t y);

// Entrada composta (IME). type: LOK_EXT_TEXTINPUT (pré-edição, ainda pode
// mudar) ou LOK_EXT_TEXTINPUT_END (confirma o texto).
PQK_EXPORT void pqk_ext_text_input(int32_t type, const char* text);
// A seleção como texto no mime pedido; responde com PQK_EVENT_TEXT_SELECTION.
PQK_EXPORT void pqk_text_selection(const char* mime);
// Cola dados (UTF-8) no cursor.
PQK_EXPORT void pqk_paste(const char* mime, const char* data);
// Devolve ao sistema a memória dos caches do LibreOffice (ao ficar ocioso).
PQK_EXPORT void pqk_trim_memory(int32_t target);

// Título da janela do app (o Flutter no Linux não tem API para isso).
PQK_EXPORT void pqk_set_window_title(const char* title);

// Tela cheia de verdade (o modo zen, Fase 2B): gtk_window_fullscreen ou
// unfullscreen, na thread principal.
PQK_EXPORT void pqk_set_fullscreen(int32_t on);

// Plugins Lua: roda o código numa caixa de areia própria, na thread de
// plugins. psito.log vira PQK_EVENT_LUA_LOG; o fim, PQK_EVENT_LUA_DONE.
PQK_EXPORT void pqk_lua_run(const char* source, const char* chunk_name,
                            int64_t memory_limit, int64_t instruction_limit);

// Medidas (Fase 0).
PQK_EXPORT int64_t pqk_resident_bytes(void);
// Latência tecla → ladrilho pronto, em microssegundos: p50, p95, máximo.
// Devolve o número de amostras.
PQK_EXPORT int32_t pqk_key_latency(int64_t* p50_us, int64_t* p95_us, int64_t* max_us);
PQK_EXPORT void pqk_reset_key_latency(void);
// Luminância média (0–255) dos ladrilhos em uso: confere o papel escuro sem
// olhar a tela.
PQK_EXPORT double pqk_debug_tiles_luma(void);

// As classes das fontes (1 mono, 2 com serifa, 4 sem serifa; 0 se não está
// instalada), uma família por linha na entrada e um número por linha na
// saída. Não passa pela thread do kit: é o fontconfig, não o LibreOffice.
// Liberar com pqk_free_string.
PQK_EXPORT char* pqk_font_classes(const char* families_by_line);

PQK_EXPORT void pqk_free_string(char* s);

#ifdef __cplusplus
}
#endif

#endif  // PSITO_QUILL_KIT_API_H_
