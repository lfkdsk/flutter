flutter pub pub run intl_translation:extract_to_arb --output-dir=res/ \lib/i10n/localization_intl.dart
flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/i10n --no-use-deferred-loading lib/i10n/localization_intl.dart res/intl_en_US.arb res/intl_zh_CN.arb
