//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <file_selector_linux/file_selector_plugin.h>
#include <psito_quill_kit/psito_quill_kit_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) file_selector_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FileSelectorPlugin");
  file_selector_plugin_register_with_registrar(file_selector_linux_registrar);
  g_autoptr(FlPluginRegistrar) psito_quill_kit_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PsitoQuillKitPlugin");
  psito_quill_kit_plugin_register_with_registrar(psito_quill_kit_registrar);
}
