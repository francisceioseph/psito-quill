#include <unistd.h>

#include <cstdio>

#include "my_application.h"

int main(int argc, char** argv) {
  int status;
  {
    g_autoptr(MyApplication) app = my_application_new();
    status = g_application_run(G_APPLICATION(app), argc, argv);
  }
  // Sai sem os destrutores estáticos. O LibreOfficeKit continua carregado no
  // processo, e os destrutores estáticos dele derrubam o app no exit()
  // (SIGSEGV em LocaleDataWrapper). Quando a janela fecha, o documento já foi
  // fechado no motor (Workspace.requestExit), e não há mais nada a gravar.
  // Veja D-027.
  fflush(nullptr);
  _exit(status);
}
