// O motor: o LibreOfficeKit do sistema atrás de uma fila (Active Object).
//
// Toda chamada pública só põe uma tarefa na fila e volta na hora. Os
// resultados saem pelo EngineSink: eventos (os do LOK, repassados, e os
// nossos, de 10000 em diante) e "a vaga N tem pixels novos".
//
// Não depende de GTK nem do Flutter, para rodar também no lok_probe e nos
// testes.
#pragma once

#include <atomic>
#include <chrono>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "task_queue.h"
#include "tile_cache.h"

struct _LibreOfficeKit;
struct _LibreOfficeKitDocument;

namespace pqk {

// Eventos próprios. Os do LOK (LOK_CALLBACK_*) passam com o número original.
enum EngineEvent : int32_t {
  kEvReady = 10000,      // payload: versão do LibreOffice (JSON do LOK)
  kEvInitFailed = 10001, // payload: motivo
  kEvOpened = 10002,     // payload: {"width":tw,"height":tw,"parts":n}
  kEvOpenFailed = 10003, // payload: motivo
  kEvTile = 10004,       // payload: "vaga,col,linha,escalaMilli"
  kEvSaved = 10005,      // payload: caminho
  kEvSaveFailed = 10006, // payload: motivo
  kEvClosed = 10007,
  kEvCommandValues = 10008,  // payload: "comando\n" + JSON
  kEvTextSelection = 10009,  // payload: "mime\n" + texto selecionado
  kEvLuaLog = 10100,     // payload: texto do psito.log
  kEvLuaDone = 10101,    // payload: {"ok":bool,"error":"..."}
};

class EngineSink {
 public:
  virtual ~EngineSink() = default;
  virtual void onEvent(int32_t type, const std::string& payload) = 0;
  virtual void onTileUpdated(int slot) = 0;
};

struct LatencyStats {
  size_t count = 0;
  double p50 = 0, p95 = 0, max = 0;  // ms
};

class LokEngine {
 public:
  LokEngine(EngineSink* sink, int tileSlots);
  ~LokEngine();

  // Tudo assíncrono.
  void init(const std::string& installPath, const std::string& profileUrl);
  void open(const std::string& path);  // "" abre um documento vazio
  void close();
  void setViewport(int32_t scaleMilli, const TwipRect& visible);
  void postKey(int type, int charCode, int keyCode);
  void postMouse(int type, int x, int y, int count, int buttons, int modifier);
  void uno(const std::string& command, const std::string& argsJson);
  // Arrasta a alça de uma imagem selecionada: type é LOK_SETGRAPHICSELECTION_START
  // (no ponto da alça) ou _END (no ponto de chegada), em twips.
  void setGraphicSelection(int type, int x, int y);
  void saveAs(const std::string& path, const std::string& format,
              const std::string& options);
  void commandValues(const std::string& command);
  // Entrada composta (IME): type é LOK_EXT_TEXTINPUT (pré-edição) ou
  // LOK_EXT_TEXTINPUT_END (confirma).
  void extTextInput(int type, const std::string& text);
  // A seleção como texto, no mime pedido; responde com kEvTextSelection.
  void textSelection(const std::string& mime);
  void paste(const std::string& mime, const std::string& data);
  // Devolve ao sistema a memória que o LibreOffice guarda em caches.
  void trimMemory(int target);
  // Redesenha todos os ladrilhos (troca de esquema de cor, por exemplo).
  void repaintAll();

  // Para o encerramento: espera a fila esvaziar e destrói o LOK.
  void shutdown();

  TileCache& tiles() { return cache_; }
  LatencyStats latency() const;
  void resetLatency();

  // Usado pelo lok_probe: espera a fila ficar vazia (não usar na UI).
  void drain();

 private:
  static void lokCallback(int type, const char* payload, void* data);
  void handleCallback(int type, const std::string& payload);
  void scheduleRender();
  void renderPass();
  void paintSlot(int index);

  EngineSink* sink_;
  TileCache cache_;
  TaskQueue queue_;

  // Só tocados na thread da fila:
  _LibreOfficeKit* kit_ = nullptr;
  _LibreOfficeKitDocument* doc_ = nullptr;
  int tileMode_ = 0;
  int32_t scaleMilli_ = 1000;
  TwipRect viewport_;
  std::vector<bool> announced_;
  std::vector<TileKey> announcedKey_;
  std::unique_ptr<uint8_t[]> scratch_;

  std::atomic<bool> renderScheduled_{false};

  // Latência tecla → ladrilho pronto.
  using Clock = std::chrono::steady_clock;
  mutable std::mutex latencyMutex_;
  bool keyPending_ = false;
  bool keyInvalidated_ = false;
  Clock::time_point keyTime_;
  std::vector<double> samples_;
};

// RSS do processo, em bytes (de /proc/self/statm).
int64_t residentBytes();

}  // namespace pqk
