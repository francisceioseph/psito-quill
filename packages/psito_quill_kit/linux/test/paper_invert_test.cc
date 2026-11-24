// O papel escuro (D-074): a luminosidade se inverte, o tom fica.
#include <gtest/gtest.h>

#include "core/lok_engine.h"

using pqk::LokEngine;

namespace {

struct Px {
  int r, g, b;
};

Px run(uint32_t rgb, uint8_t alpha = 255) {
  static uint8_t lut[3][256];
  // O papel e a tinta do tema escuro; o papel do motor, branco.
  LokEngine::buildInvertLut(lut, 0x1E1F22, 0xE6E6E6, 0xFFFFFF);
  uint8_t px[4] = {static_cast<uint8_t>(rgb >> 16), static_cast<uint8_t>(rgb >> 8), static_cast<uint8_t>(rgb), alpha};
  LokEngine::invertPixels(px, 1, lut);
  return {px[0], px[1], px[2]};
}

}  // namespace

TEST(PaperInvert, PapelBrancoViraOPapelEscuro) {
  const Px p = run(0xFFFFFF);
  EXPECT_EQ(p.r, 0x1E);
  EXPECT_EQ(p.g, 0x1F);
  EXPECT_EQ(p.b, 0x22);
}

TEST(PaperInvert, PretoViraATinta) {
  const Px p = run(0x000000);
  EXPECT_EQ(p.r, 0xE6);
  EXPECT_EQ(p.b, 0xE6);
}

TEST(PaperInvert, CinzaEscuroFicaClaro) {
  const Px p = run(0x333333);
  EXPECT_GT(p.r, 0xB0);
}

TEST(PaperInvert, VermelhoContinuaVermelhoEMaisClaro) {
  const Px p = run(0xC00000);
  EXPECT_GT(p.r, 0xC0);
  EXPECT_GT(p.r, p.g + 80);
  EXPECT_NEAR(p.g, p.b, 3);
}

TEST(PaperInvert, TransparenteNaoMuda) {
  uint8_t lut[3][256];
  LokEngine::buildInvertLut(lut, 0x1E1F22, 0xE6E6E6, 0xFFFFFF);
  uint8_t px[4] = {0, 0, 0, 0};
  LokEngine::invertPixels(px, 1, lut);
  EXPECT_EQ(px[0] + px[1] + px[2] + px[3], 0);
}

TEST(PaperInvert, MeioTransparenteFicaPreMultiplicado) {
  // Branco com metade do alfa (128, pré-multiplicado): o papel escuro com o
  // mesmo alfa.
  uint8_t lut[3][256];
  LokEngine::buildInvertLut(lut, 0x1E1F22, 0xE6E6E6, 0xFFFFFF);
  uint8_t px[4] = {128, 128, 128, 128};
  LokEngine::invertPixels(px, 1, lut);
  EXPECT_EQ(px[3], 128);
  EXPECT_NEAR(px[0], 0x1E * 128 / 255, 1);
}
