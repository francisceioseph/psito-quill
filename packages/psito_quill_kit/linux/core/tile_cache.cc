#include "tile_cache.h"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace pqk {

double tileTwips(int32_t scaleMilli) {
  return kTileSize * kTwipsPerPixel * 1000.0 / scaleMilli;
}

TwipRect tileRect(const TileKey& key) {
  const double t = tileTwips(key.scaleMilli);
  // Bordas arredondadas a partir do índice, para ladrilhos vizinhos não
  // deixarem fresta nem se sobreporem por arredondamento.
  const int64_t x0 = std::llround(key.col * t), x1 = std::llround((key.col + 1) * t);
  const int64_t y0 = std::llround(key.row * t), y1 = std::llround((key.row + 1) * t);
  return {x0, y0, x1 - x0, y1 - y0};
}

std::vector<TileKey> tilesCovering(const TwipRect& area, int32_t scaleMilli) {
  std::vector<TileKey> out;
  if (area.w <= 0 || area.h <= 0 || scaleMilli <= 0) return out;
  const double t = tileTwips(scaleMilli);
  const int c0 = std::max<int>(0, static_cast<int>(std::floor(area.x / t)));
  const int r0 = std::max<int>(0, static_cast<int>(std::floor(area.y / t)));
  const int c1 = static_cast<int>(std::floor((area.x + area.w - 1) / t));
  const int r1 = static_cast<int>(std::floor((area.y + area.h - 1) / t));
  for (int r = r0; r <= r1; ++r)
    for (int c = c0; c <= c1; ++c) out.push_back({c, r, scaleMilli});
  return out;
}

TileCache::TileCache(int slotCount) {
  slots_.reserve(slotCount);
  for (int i = 0; i < slotCount; ++i) {
    auto s = std::make_unique<TileSlot>();
    s->pixels = std::make_unique<uint8_t[]>(kTileBytes);
    std::memset(s->pixels.get(), 0, kTileBytes);
    slots_.push_back(std::move(s));
  }
}

int TileCache::find(const TileKey& key) const {
  auto it = index_.find(key);
  return it == index_.end() ? -1 : it->second;
}

void TileCache::touch(int index) { slots_[index]->lastUsed = ++clock_; }

int TileCache::acquire(const TileKey& key, const std::vector<int>& pinned) {
  int found = find(key);
  if (found >= 0) {
    touch(found);
    return found;
  }
  int victim = -1;
  uint64_t oldest = UINT64_MAX;
  for (int i = 0; i < slotCount(); ++i) {
    TileSlot& s = *slots_[i];
    if (!s.assigned) {  // vaga nunca usada: a melhor escolha
      victim = i;
      break;
    }
    if (std::find(pinned.begin(), pinned.end(), i) != pinned.end()) continue;
    if (s.lastUsed < oldest) {
      oldest = s.lastUsed;
      victim = i;
    }
  }
  if (victim < 0) return -1;
  TileSlot& s = *slots_[victim];
  if (s.assigned) index_.erase(s.key);
  s.key = key;
  s.assigned = true;
  s.dirty = true;
  index_[key] = victim;
  touch(victim);
  return victim;
}

std::vector<int> TileCache::invalidate(const TwipRect& area) {
  std::vector<int> out;
  for (int i = 0; i < slotCount(); ++i) {
    TileSlot& s = *slots_[i];
    if (s.assigned && tileRect(s.key).intersects(area)) {
      s.dirty = true;
      out.push_back(i);
    }
  }
  return out;
}

std::vector<int> TileCache::invalidateAll() {
  std::vector<int> out;
  for (int i = 0; i < slotCount(); ++i) {
    if (slots_[i]->assigned) {
      slots_[i]->dirty = true;
      out.push_back(i);
    }
  }
  return out;
}

void TileCache::clear() {
  index_.clear();
  for (auto& s : slots_) {
    s->assigned = false;
    s->dirty = true;
    s->lastUsed = 0;
  }
}

}  // namespace pqk
