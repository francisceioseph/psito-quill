#include "core/tile_cache.h"

#include <gtest/gtest.h>

#include <set>

using namespace pqk;

TEST(TileGeometry, TileSideInTwipsFollowsScale) {
  EXPECT_DOUBLE_EQ(tileTwips(1000), 3840.0);  // 256 px × 15 twips
  EXPECT_DOUBLE_EQ(tileTwips(1250), 3072.0);
  EXPECT_DOUBLE_EQ(tileTwips(2000), 1920.0);
}

TEST(TileGeometry, NeighbourTilesShareEdgesWithoutGaps) {
  // 1,5x dá 2560 twips; 1,1x dá frações: as bordas ainda precisam encostar.
  for (int scale : {1000, 1100, 1250, 1500, 1750}) {
    for (int c = 0; c < 20; ++c) {
      TwipRect a = tileRect({c, 0, scale}), b = tileRect({c + 1, 0, scale});
      EXPECT_EQ(a.x + a.w, b.x) << "escala " << scale << " col " << c;
    }
  }
}

TEST(TileGeometry, CoveringReturnsEveryTileTouched) {
  // De 100 a 3840+100 cobre duas colunas; altura de uma linha só.
  auto keys = tilesCovering({100, 0, 3840, 3840}, 1000);
  ASSERT_EQ(keys.size(), 2u);
  EXPECT_EQ(keys[0].col, 0);
  EXPECT_EQ(keys[1].col, 1);
  EXPECT_TRUE(tilesCovering({0, 0, 0, 100}, 1000).empty());
}

TEST(TileCache, MemoryIsFixedBySlotCount) {
  TileCache c(64);
  EXPECT_EQ(c.bytes(), 64u * 256 * 256 * 4);  // 16 MB, seja qual for o documento
}

TEST(TileCache, AcquireReusesTheSameSlotForTheSameKey) {
  TileCache c(4);
  int a = c.acquire({0, 0, 1000}, {});
  EXPECT_TRUE(c.slot(a).dirty);
  c.slot(a).dirty = false;
  EXPECT_EQ(c.acquire({0, 0, 1000}, {}), a);
  EXPECT_FALSE(c.slot(a).dirty);  // já desenhado: não repinta
}

TEST(TileCache, EvictsLeastRecentlyUsedButNeverPinned) {
  TileCache c(3);
  int s0 = c.acquire({0, 0, 1000}, {});
  int s1 = c.acquire({0, 1, 1000}, {});
  int s2 = c.acquire({0, 2, 1000}, {});
  c.touch(s0);  // s1 vira o mais antigo
  int s3 = c.acquire({0, 3, 1000}, {});
  EXPECT_EQ(s3, s1);
  EXPECT_EQ(c.find({0, 1, 1000}), -1);
  // Com s2 e s0 visíveis e s3 também, não há vaga.
  EXPECT_EQ(c.acquire({0, 4, 1000}, {s0, s2, s3}), -1);
}

TEST(TileCache, InvalidateMarksOnlyTouchedTiles) {
  TileCache c(8);
  std::set<int> clean;
  for (int r = 0; r < 4; ++r) {
    int s = c.acquire({0, r, 1000}, {});
    c.slot(s).dirty = false;
  }
  // Um retângulo dentro da linha 2 (y de 7680 a 11520).
  auto hit = c.invalidate({200, 8000, 500, 300});
  ASSERT_EQ(hit.size(), 1u);
  EXPECT_EQ(c.slot(hit[0]).key.row, 2);
  EXPECT_TRUE(c.slot(hit[0]).dirty);
  EXPECT_FALSE(c.slot(c.find({0, 1, 1000})).dirty);
  EXPECT_EQ(c.invalidateAll().size(), 4u);
}

TEST(TileCache, ClearForgetsEverything) {
  TileCache c(2);
  c.acquire({1, 1, 1000}, {});
  c.clear();
  EXPECT_EQ(c.find({1, 1, 1000}), -1);
}
