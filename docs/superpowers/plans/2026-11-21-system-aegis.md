# System Aegis Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Rename the entire mod to System Aegis for a separate, complete release.
**Architecture:** One package named System Aegis in System-Aegis/. Rename old item identifiers, Lua modules, globals, protocols, custom localization keys, assets, tools, tests and documentation together. Remove the previous Workshop identity.
**Tech Stack:** Barotrauma XML, Lua 5.2, Python, PNG, OGG.
**Spec:** User request of 2026-11-21: all branding, including folder names, becomes System Aegis; publish as a separate full mod.

## Global Constraints

- Display name: System Aegis; package directory and ZIP prefix: System-Aegis.
- No dependency on the previous mod; keep the existing LuaCs requirement.
- New item identifiers use aegis; no old-identifier compatibility aliases.
- Keep native game identifiers and internal hidden helper items functional.
- Keep mechanics, recipes, balance and asset contents unchanged.
- Do not publish, modify an installed game, or rewrite Git history.

## Review Focus

- Manifest and every nested XML/Lua asset path resolve, including case on Linux.
- All custom identifiers, translations, recipes, globals and network keys agree.
- No previous Workshop ID, old package branding or old module paths in current package.
- Historical benchmark helpers must read renamed sources from historical Git paths.
- ZIP contains the complete mod and no development/runtime test scripts.

### Task 1: Rename package and all references

- [x] Read sources, inventory identifiers and verify baseline: 705 tests pass.
- [x] Add package checks for independent identity, namespaced identifiers and complete manifest references; run to confirm failure before rename.
- [x] Apply one consistent mapping to tracked source/text files and filenames, preserving native game APIs and binary data.
- [x] Update release documentation, names in every existing translation and version to 1.3.27.
- [x] Run the full suite and validator against installed game content.

### Task 2: Verify release archive

- [x] Review names, references, translations and development tools.
- [x] Build output/System-Aegis-1.3.27.zip and verify contents, manifest and SHA-256.
- [x] Report exact validation and save compatibility limits.


## Completion evidence

- Baseline: 705 tests passed; package-identity tests failed before rename.
- Final: 711 tests passed; native-content validator passed 18 XML and 62 production Lua 5.2 modules.
- All runtime probe Lua syntax checked; historical benchmark tool runs before/after.
- Independent review confirmed exact-case asset paths, Lua imports, custom identifiers, localization and byte preservation of all 50 PNG/OGG assets.
- Polish documentation encoding corrected; all new release copy checked for replacement question marks.
- Archive verified against every source file and SHA-256 saved beside ZIP.
- Legacy branding scan of active package, source tools, tests and documentation: zero matches.
- Local installations, historical ZIPs, raw performance runs and Git history are development/archive data outside the release package.


## Outer checkout directory

The final attempt to rename the outer checkout to System-Aegis failed with
Windows error that another process is using the directory. No directory was
moved. `tools/rename_repository.ps1` verifies both paths and performs that
remaining rename after processes holding the checkout are closed. Its
PowerShell syntax and complete path checks passed using -WhatIf; no second
rename was attempted.
Runtime capture probes now accept AegisCaptureRoot and have portable defaults.
