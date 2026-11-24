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
#include <utility>
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
  kEvOpened = 10002,     // payload: {"id":n,"width":tw,"height":tw,"parts":n}
  kEvOpenFailed = 10003, // payload: motivo
  kEvTile = 10004,       // payload: "vaga,col,linha,escalaMilli"
  kEvSaved = 10005,      // payload: caminho
  kEvSaveFailed = 10006, // payload: motivo
  kEvClosed = 10007,     // payload: o número do documento
  kEvCommandValues = 10008,  // payload: "comando\n" + JSON
  kEvTextSelection = 10009,  // payload: "mime\n" + texto selecionado
  kEvActivated = 10010,  // payload: {"id":n,"width":tw,"height":tw,"parts":n}
  kEvConverted = 10011,  // payload: {"id":n,"ok":bool,"error":"..."}
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
  // Os documentos (D-054): vários abertos, um ativo. Toda chamada abaixo vai
  // ao ativo, e os callbacks dos outros são descartados.
  // Abre mais um e o ativa, sem fechar os outros ("" abre um vazio).
  void open(const std::string& path);
  // Troca o ativo: limpa as vagas e repinta. Responde com kEvActivated.
  void activate(int id);
  // Fecha o ativo (close) ou um pelo número. Responde com kEvClosed.
  void close();
  void closeDocument(int id);
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
  // Liga os callbacks de acessibilidade do documento ativo (D-067): o
  // parágrafo do cursor (62) e a posição do cursor nele (63).
  void setAccessibility(bool on);
  // Abre [path] (um documento pequeno com texto) sem mostrar: a ortografia
  // automática carrega o dicionário enquanto a tela inicial está aberta, e o
  // primeiro capítulo aberto depois não espera por ele (D-069). O documento
  // oculto fecha quando outro abre. Apaga o arquivo logo depois de abrir.
  void preloadSpelling(const std::string& path);
  // As variáveis do LOK (as línguas da ortografia, o SAL_LOG). Num processo
  // com outras threads, chame no começo do main: o setenv numa thread
  // enquanto outra lê o ambiente (o fontconfig do GTK) derruba o processo
  // (D-072).
  static void prepareEnvironment();
  // Abre [src] oculto, salva em [dst] no [format] e fecha, sem tocar nos
  // documentos das abas (o importador de livros, D-071). [src] vazio: um
  // documento novo. Responde com kEvConverted e o [id] de quem pediu.
  void convert(int id, const std::string& src, const std::string& dst, const std::string& format);
  void repaintAll();

  /// O papel escuro (D-074): inverte a luminosidade dos ladrilhos, com o tom
  /// mantido. Na fila do kit, antes do próximo repaintAll.
  void setPaperInvert(bool on, uint32_t paper, uint32_t ink, uint32_t srcPaper);

  /// Inverte [n] pixels RGBA (pré-multiplicados) pela tabela. Público para
  /// o teste.
  static void invertPixels(uint8_t* rgba, int n, const uint8_t lut[3][256]);
  static void buildInvertLut(uint8_t lut[3][256], uint32_t paper, uint32_t ink, uint32_t srcPaper);

  // Para o encerramento: espera a fila esvaziar e destrói o LOK.
  void shutdown();

  TileCache& tiles() { return cache_; }
  LatencyStats latency() const;
  void resetLatency();

  // Usado pelo lok_probe: espera a fila ficar vazia (não usar na UI).
  void drain();

 private:
  struct Doc {
    LokEngine* engine = nullptr;
    int id = 0;
    _LibreOfficeKitDocument* doc = nullptr;
    int tileMode = 0;
    // A vista do documento (getView logo depois de abrir).
    int view = -1;
    // Os callbacks que chegam antes do OPENED, guardados até ele sair.
    std::mutex mutex;
    bool announced = false;
    std::vector<std::pair<int, std::string>> early;
  };

  static void lokCallback(int type, const char* payload, void* data);
  // O callback do escritório (sem documento): o progresso de abrir e salvar
  // (STATUS_INDICATOR, 9 a 11) e o pedido de senha (D-066).
  static void officeCallback(int type, const char* payload, void* data);
  void makeActive(Doc* d);
  void destroyDoc(int id);
  std::string sizeJson(const Doc& d);
  void handleCallback(int type, const std::string& payload);
  void scheduleRender();
  void renderPass();
  void paintSlot(int index);

  EngineSink* sink_;
  TileCache cache_;
  TaskQueue queue_;

  // Só tocados na thread da fila:
  _LibreOfficeKit* kit_ = nullptr;
  std::vector<std::unique_ptr<Doc>> docs_;
  int nextId_ = 1;
  // O ativo (doc_ e tileMode_ são os dele). Atômico: os callbacks leem.
  std::atomic<int> activeId_{0};
  _LibreOfficeKitDocument* doc_ = nullptr;
  // O documento oculto do preloadSpelling, até o próximo abrir.
  _LibreOfficeKitDocument* spellDoc_ = nullptr;
  int tileMode_ = 0;
  int view_ = -1;
  // O postUnoCommand vai ao quadro "atual" do LibreOffice, que é global: com
  // outro documento aberto e fechado no meio (uma conversão, o dicionário),
  // ou com abas, ele deixa de ser o do ativo. Chamar antes de cada comando.
  void focusView();
  // Só a thread do kit lê e escreve (setPaperInvert e paintSlot).
  bool invert_ = false;
  uint8_t invertLut_[3][256] = {};
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
