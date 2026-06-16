# ShortHand

ShortHand was a server-side scripting language for dynamic web pages. It lived in the era when CGI was normal, Apache module deployment mattered, and web apps often shipped as a single self-contained script plus a manual.

This repository is a Zig-powered revival experiment. The goal is to preserve the original language and runtime behavior as faithfully as possible, then add modern safety features as explicit opt-ins instead of quietly rewriting the language underneath old code.

## Why This Exists

The original ShortHand was built to make web scripting easier to learn, easier to deploy, and easier to ship across hosts. The archived manual describes support for:

- embedded script tags inside HTML
- CGI, Apache, IIS, and Aprelium/Abyss deployment
- MySQL and ODBC
- cookies, file I/O, SMTP, dates, and string helpers
- a small object model with built-in `File`, `Cookie`, `Connection`, `RecordSet`, `DDL`, and `SMTP` types

That combination made it practical for the kind of small, fast-moving web apps that were common in the early 2000s. This repo keeps that spirit, but in a form that is easier to read, test, and evolve.

## What We Kept

- Preferred source extension: `.short`
- Legacy aliases: `.tran`, `.shh`, `.shl`
- Manual-first compatibility rules
- CGI-style execution as the baseline deployment model
- Aprelium/Abyss Web Server as a first-class compatibility target
- Apache compatibility as a current target

## What Changed

- The interpreter is written in Zig instead of Flex/Bison plus C/C++
- The runtime is structured around explicit request, response, and deployment state
- Strict mode is opt-in and preserves legacy loose coercion by default
- Regex is available as a separate modern extension API
- The file object, dates, text helpers, numeric helpers, and database compatibility layer are all being rebuilt against the manual

## Repository Layout

- `src/`: Zig implementation of the lexer, parser, runtime, and compatibility layers
- `tests/`: smoke tests and compatibility checks
- `examples/`: sample `.short` files
- `docs/manual/`: Markdown republish of the archived help manual
- `shorthand.feature-map.md`: working feature map distilled from the manual
- `shorthand.chm`: original archived Windows help file

## Build And Run

```bash
zig build
zig build test
zig build run -- help
zig build run -- run examples/hello.short
zig build run -- --strict run examples/hello.short
```

## Documentation

- [Manual index](docs/manual/index.md)
- [Project notes and feature map](shorthand.feature-map.md)

## Current Status

This is a working revival, not a finished product. The language core is being rebuilt against the manual as the source of truth, and the modern additions are being kept separate so they do not overwrite the old behavior by accident.

If you are looking for the shortest summary: this is an attempt to make ShortHand feel like ShortHand again, while still being usable on a modern host.
