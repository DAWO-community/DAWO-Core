# Localization

System language, regional formats, and which languages a user can switch the
desktop to.

## Key Files
- `languages.nix` - the `dawo.localization` block: system language, regional
  formats, time zone, the set of offered languages, and their spell checkers.

## Responsibilities
- The language the desktop is written in (`dawo.localization.options.systemLanguage`).
- The conventions used for dates, numbers, currency and paper
  (`dawo.localization.options.regionalFormats`), kept separate from the language
  on purpose.
- Time zone, with the hardware clock on UTC.
- Generating every offered locale, so a user can change the desktop language in
  Plasma or GNOME without a rebuild. A locale that was not generated cannot be
  selected, which is the usual reason a language menu looks empty.
- A hunspell dictionary per offered language.

## What this does not do
Application interfaces follow their own packaging. The desktop and the system
messages switch with the locale; an application that ships its translations as a
separate package (a browser language pack, for instance) needs that package as
well. Keyboard layout is a separate concern and lives with the desktop
configuration, not here: a user typing Ukrainian on a device imaged in Dutch
wants both, and neither implies the other.
