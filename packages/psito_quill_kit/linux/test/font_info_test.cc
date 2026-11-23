// A classificação das fontes pelo fontconfig (Fase 2B, Etapa 3). Usa as
// fontes que vêm com o LibreOffice (Liberation) e o DejaVu do Ubuntu.
#include "core/font_info.h"

#include <gtest/gtest.h>

using namespace pqk;

TEST(FontInfo, ClassesDasFontesConhecidas) {
  EXPECT_EQ(classifyFonts("Liberation Mono"), "1");
  EXPECT_EQ(classifyFonts("Liberation Serif"), "2");
  EXPECT_EQ(classifyFonts("Liberation Sans"), "4");
}

TEST(FontInfo, UmaPorLinhaENaoInstaladaEhZero) {
  EXPECT_EQ(classifyFonts("DejaVu Sans Mono\nNao Existe Esta Fonte\nDejaVu Serif"), "1\n0\n2");
  EXPECT_EQ(classifyFonts(""), "");
}
