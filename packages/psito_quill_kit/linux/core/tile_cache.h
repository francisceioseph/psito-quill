// Flyweight + LRU: um conjunto fixo de "vagas" de ladrilho.
//
// Cada vaga tem um buffer RGBA de kTileSize² pixels e, no app, uma textura do
// Flutter. A memória é fixa (vagas × 256 KB), seja qual for o documento. Pedir
// um ladrilho que não está em nenhuma vaga reaproveita a vaga usada há mais
// tempo, desde que ela não esteja entre as visíveis.
//
// Coordenadas: o documento é medido em twips (1/1440 pol). Com escala `s`
// (pixels físicos por pixel lógico × zoom), 1 px físico = 15/s twips.
#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace pqk {

constexpr int kTileSize = 256;           // pixels físicos
constexpr int kTileBytes = kTileSize * kTileSize * 4;
constexpr double kTwipsPerPixel = 15.0;  // a 96 dpi e zoom 1

struct TileKey {
  int32_t col = 0;
  int32_t row = 0;
  int32_t scaleMilli = 1000;  // escala × 1000, para a chave ser inteira

  bool operator==(const TileKey& o) const {
    return col == o.col && row == o.row && scaleMilli == o.scaleMilli;
  }
};

struct TileKeyHash {
  size_t operator()(const TileKey& k) const {
    return (static_cast<size_t>(k.col) * 73856093u) ^
           (static_cast<size_t>(k.row) * 19349663u) ^
           (static_cast<size_t>(k.scaleMilli) * 83492791u);
  }
};

// Retângulo em twips.
struct TwipRect {
  int64_t x = 0, y = 0, w = 0, h = 0;
  bool intersects(const TwipRect& o) const {
    return x < o.x + o.w && o.x < x + w && y < o.y + o.h && o.y < y + h;
  }
};

// Lado do ladrilho em twips para a escala dada.
double tileTwips(int32_t scaleMilli);
TwipRect tileRect(const TileKey& key);
// Ladrilhos que cobrem `area` na escala dada.
std::vector<TileKey> tilesCovering(const TwipRect& area, int32_t scaleMilli);

struct TileSlot {
  std::mutex mutex;  // protege `pixels` entre a thread do kit e a de raster
  std::unique_ptr<uint8_t[]> pixels;  // RGBA, kTileBytes
  TileKey key;
  bool assigned = false;
  bool dirty = true;  // precisa ser (re)desenhado
  uint64_t lastUsed = 0;
};

class TileCache {
 public:
  explicit TileCache(int slotCount);

  int slotCount() const { return static_cast<int>(slots_.size()); }
  TileSlot& slot(int index) { return *slots_[index]; }

  // Vaga que guarda `key`, ou -1.
  int find(const TileKey& key) const;

  // Vaga para `key`: a que já tem, ou uma reaproveitada (LRU), marcada suja.
  // As vagas em `pinned` (as visíveis) não são reaproveitadas. -1 se não há.
  int acquire(const TileKey& key, const std::vector<int>& pinned);

  void touch(int index);

  // Marca sujas as vagas que tocam `area`. Devolve os índices.
  std::vector<int> invalidate(const TwipRect& area);
  // Marca todas sujas (o motor mandou "EMPTY": tudo mudou).
  std::vector<int> invalidateAll();
  // Esquece todas (documento fechado).
  void clear();

  size_t bytes() const { return slots_.size() * static_cast<size_t>(kTileBytes); }

 private:
  std::vector<std::unique_ptr<TileSlot>> slots_;
  std::unordered_map<TileKey, int, TileKeyHash> index_;
  uint64_t clock_ = 0;
};

}  // namespace pqk
