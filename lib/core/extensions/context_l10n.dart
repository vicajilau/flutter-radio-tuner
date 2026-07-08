import 'package:flutter/widgets.dart';
import 'package:flutter_radio_tuner/l10n/app_localizations.dart';

/// Shortcut extension on BuildContext to get AppLocalizations easily.
extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
