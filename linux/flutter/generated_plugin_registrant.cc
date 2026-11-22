//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <psito_quill_kit/psito_quill_kit_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) psito_quill_kit_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PsitoQuillKitPlugin");
  psito_quill_kit_plugin_register_with_registrar(psito_quill_kit_registrar);
}
