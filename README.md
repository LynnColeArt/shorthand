# short

Zig scaffold for the ShortHand revival experiment.

Preferred source extension:
- `.short`

Legacy aliases kept for compatibility:
- `.tran`
- `.shh`
- `.shl`

## Layout

- `src/root.zig`: package root and module re-exports
- `src/main.zig`: CLI entrypoint for the runtime
- `src/lexer.zig`: tokenization boundary
- `src/ast.zig`: syntax tree shapes
- `src/parser.zig`: parser boundary
- `src/cgi.zig`: CGI environment adapter
- `src/runtime.zig`: execution boundary and host contract
- `src/deployment.zig`: deployment profile and server metadata
- `src/request.zig`: request-scoped state
- `src/response.zig`: response state and header timing
- `src/value.zig`: legacy value model
- `src/render.zig`: output and HTML escaping
- `src/builtins.zig`: built-in dispatch surface
- `tests/smoke.zig`: small compile-and-run checks
- `examples/hello.short`: starter example

## Commands

- `zig build`
- `zig build run -- help`
- `zig build run -- lex examples/hello.short`
- `zig build run -- parse examples/hello.short`
- `zig build run -- cgi`
- `zig build run -- run examples/hello.short`
- `zig build run -- --strict run examples/hello.short`
- `zig build test`

## Direction

The first pass should stay interpreter-first:
- lex
- parse
- execute
- then optimize

That keeps the experiment faithful to the old language while leaving room for a modern host and safer defaults later.

Deployment compatibility target:
- Aprelium/Abyss Web Server

Runtime contract:
- `DeploymentProfile` identifies the host flavor and server metadata.
- `RequestContext` carries request facts only.
- `ResponseState` tracks status, body start, and header mutability separately.
- `Runtime` groups those pieces together so CGI, Apache, and Abyss adapters can share one execution model.

Response behavior:
- `header()` mutates metadata until headers are committed.
- `SetCookie()` serializes cookie state into `Set-Cookie` response lines.
- `redirect()` sets a 302 response and appends a `Location` header.
- Header mutations stop once the body begins or headers are emitted.

Strict mode:
- Legacy coercion stays the default.
- `--strict` enables opt-in type checks for arithmetic, comparisons, and boolean contexts.
- In strict mode, response-control APIs reject silent coercion at the emission boundary.

Regex extension:
- `regexmatch(pattern, subject)` uses PCRE2/Perl-style syntax and returns a boolean.
- `regexreplace(pattern, replacement, subject)` applies global replacements and supports `$1` and `${name}` captures.
- `regexextract(pattern, subject, [group])` returns the first match or an optional capture.
- `regexcapture(...)` is an alias for `regexextract(...)`.
- PHP-style aliases `preg_match` and `preg_replace` are accepted too.

Core text helpers:
- `string(value)` forces an explicit string conversion.
- `format(number, precision)` formats numbers with fixed decimals.
- `replace(source, pattern, replacement)` performs case-sensitive global string replacement.
- `translate(source, ch1, ch2)` replaces one byte with another.
- `strpos(source, pattern)` returns a zero-based offset or `-1`.
- `lc(string)` and `uc(string)` fold ASCII case for legacy byte-oriented scripts.

Numeric helpers:
- `max(...)` and `min(...)` compare values numerically and preserve float results when a float wins.
- `rand()` returns a nonnegative integer across the full legacy range.
- `rand(maximum)` returns a value from `0` through `maximum`.
- `rand(minimum, maximum)` returns a value within the inclusive range, regardless of argument order.

Date / time helpers:
- `date(year, month, day)` builds a midnight date from calendar parts.
- `date(string)` parses legacy date and timestamp forms.
- `FormatDate(d, format)` uses strftime-style tokens to render a date value.
- `now()`, `AddHours()`, `AddMinutes()`, and `AddSeconds()` operate on epoch-second date values.

File helpers:
- `FileExists(name)` returns `true` for readable files and `false` otherwise.
- `FileSize(filename)` returns a byte count or `-1` if the file cannot be read.

File objects:
- `new File(FileName [, OpenMode])` opens immediately and stores any open failure in `error` instead of raising.
- Default open mode is `"r"`.
- Supported open modes follow the legacy `fopen`-style set: `r`, `r+`, `w`, `w+`, `a`, `a+`.
- `read([count])` returns up to `count` bytes, or the whole remaining file when omitted or zero, and truncates at the first NUL byte.
- `readln()` reads through newline boundaries and strips a trailing `\r` before `\n`.
- `write(data [, length])` returns the number of bytes written.
- `close()`, `eof()`, and `rewind()` behave like the legacy file object.
- `name`, `mode`, and `error` are exposed as properties.
