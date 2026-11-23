// Os temas na ordem das preferências e do menu Exibir › Tema, com o nome.
import '../../l10n/gen/app_localizations.dart';

List<(String, String)> themeChoices(AppLocalizations l10n) => [
      ('claro', l10n.themeClaro),
      ('escuro', l10n.themeEscuro),
      ('sepia', l10n.themeSepia),
      ('altoContrasteEscuro', l10n.themeHighContrastDark),
      ('altoContrasteClaro', l10n.themeHighContrastLight),
      ('classico97', l10n.themeClassico),
    ];
