# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This repo stores **LMC (Google Camera port) configuration profiles** as Android `SharedPreferences` XML exports. Each `*.xml` at the repo root is a standalone settings dump — typically named after a device/sensor codename (e.g. `oke.xml`) — that an LMC user imports into the app to apply tuning for a specific phone or use case.

There is **no build, test, lint, or runtime** in this repo. Work consists of editing XML values, adding new device profiles, or diffing profiles against each other. Do not invent tooling that isn't here.

## File format

Every file follows Android's `SharedPreferences` on-disk schema:

```xml
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <string name="..."></string>
    <int name="..." value="..." />
    <boolean name="..." value="..." />
    <long name="..." value="..." />
</map>
```

Constraints to preserve when editing — LMC's importer is strict and will silently drop malformed entries:

- Keep the `standalone='yes'` prolog and single `<map>` root.
- Match the element name to the value type. `<string>` wraps the value in the element body; `<int>`/`<boolean>`/`<long>` are self-closing with a `value=` attribute. Do **not** convert one to the other to "tidy up."
- Empty string keys are intentional (`<string name="lib_user_value_2_pro"></string>`) — they represent "use default," not "missing." Don't delete them.
- Numeric strings (e.g. `<string name="pref_qjpg_key">100</string>`) are stored as strings on purpose; do not retype them as `<int>`.

## Key naming conventions

Keys cluster into a few families. Understanding the suffix scheme is the main thing that isn't obvious from looking at one line:

- **Prefixes** — `lib_*` are image-processing pipeline knobs (sabre, chroma, luma, sharp, hdr, noise modeler); `pref_*` are app-level preferences (codec, AWB, watermark, modes); `cw_*` / `gr_` / `bg_` / `bl0_` are white-balance / black-level constants.
- **Per-camera/per-mode suffixes** — many settings repeat across cameras and modes via suffix:
  - bare key (e.g. `lib_sabre_contrast_key`) — primary rear camera, default mode
  - `_front` — front camera variant
  - `_pro` — Pro / manual mode variant
  - `_key_2` … `_key_5` — numbered slots for additional lenses/modes (wide, tele, etc.)
- When changing a setting, check whether parallel `_front` / `_pro` / `_key_N` variants exist and decide deliberately whether the change should apply to one camera or all of them. Editing only the bare key while leaving `_key_2..5` at old values is a common source of "my change didn't take effect on the wide lens" confusion.

## Working with these files

- A file has ~2.6k entries; use Grep with the key name (or a prefix like `lib_sabre_`) rather than reading the file top-to-bottom.
- Key order in the file is **not** meaningful — Android writes in hashmap order. Don't reorder to "group related keys"; it produces enormous, meaningless diffs.
- When comparing two profiles, prefer `git diff --word-diff` or sorting both with `sort` before diffing, since hashmap-order churn dwarfs real changes.
- Treat timestamp-like keys (`tooltip_latest_impression_timestamp_*`, `pref_key_reboot_completed`, `finish_video_capture`) as user-session state, not tuning. They have no effect on image output and shouldn't be hand-edited.
