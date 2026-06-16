# ShortHand Feature Map

Source of truth for this pass:
- [`shorthand.chm`](./shorthand.chm)

## What ShortHand Is

ShortHand is a server-side scripting language for dynamic web pages.

The manual describes:
- Embedded script blocks inside HTML
- CGI, Apache module, and IIS deployment modes
- Built-in support for request/response handling, files, dates, strings, cookies, e-mail, and databases
- A small object system with a handful of built-in object types

## Core Syntax

Supported script delimiters:
- `<~ ... ~>`
- `<% ... %>`
- `<? ... ?>`

Expression-printing variants:
- `<~@ ... ~>`
- `<%= ... %>`
- `<?= ... ?>`

Basic statement model:
- One statement per line inside script tags
- Unescaped HTML is emitted as output
- `PRINT` and `PRINTLN` write to output

Comments:
- Single-quote comments only
- A comment runs to end of line or end of script tag
- Single quotes can also start string literals, so the parser distinguishes them by context

## Language Surface

Control flow:
- `IF / THEN / ELSE / ELSEIF`
- `FOR`
- `WHILE`
- `FOREACH`
- `GRID`
- `BREAK`
- `CONTINUE`
- `RETURN`
- `INCLUDE`
- `JUMP`
- `EXIT`

Functions:
- Built-in and user-defined functions
- `FUNCTION ... END FUNCTION`
- Functions must be defined before use
- Parameters are optional, but parentheses are required

Objects:
- `NEW ObjectType(...)`
- Methods called with dot syntax
- Properties are mutable where the object docs allow it
- `[]` is the only indexing syntax
- Dense arrays are 1-based
- Associative maps use string keys

## Data Model

Types documented by the manual:
- Numbers
- Strings
- Dates
- Objects
- Dense arrays
- Associative maps
- NULL

Important behavior notes:
- Variables are case-insensitive
- Map keys are case-sensitive
- Object and method names are case-insensitive in practice
- `NULL` behaves like empty string in string context, `0` in numeric context, and `FALSE` in boolean context
- The docs say strings are not Unicode / multibyte aware

## Built-In Functions

Request / response / CGI:
- `Q(name)` for GET variables
- `F(name)` for POST variables
- `ENV(name)` for OS / CGI environment variables
- `GetCookie(name)`
- `SetCookie(cookieObject)`
- `header(name, value)`
- `redirect(url)`
- `exit()`
- `urlencode(string)`
- `urldecode(string)`

String / text:
- `string(value)`
- `int(number)`
- `float(number, spaces)` in the older docs, with a doc page that looks inconsistent
- `format(number, precision)`
- `replace(source, pattern, replacement)`
- `regexmatch(pattern, subject)`
- `regexvalid(pattern)`
- `regexreplace(pattern, replacement, subject)`
- `regexextract(pattern, subject, [group])`
- `translate(source, ch1, ch2)`
- `strpos(source, pattern)`
- `substring(source, start, [length])`
- `length(string)`
- `lc(string)`
- `uc(string)`

Date / time:
- `date(year, month, day)`
- `date(string)`
- `now()`
- `FormatDate(d, format)`
- `AddHours(d, number)`
- `AddMinutes(d, number)`
- `AddSeconds(d, number)`

Numeric helpers:
- `max(...)`
- `min(...)`
- `rand()`
- `rand(maximum)`
- `rand(minimum, maximum)`

Container helpers:
- `allocated(value)`
- `size(value)`
- `shape(array)`
- `lbound(array)`
- `ubound(array)`
- `keys(map)`
- `values(container)`
- `contains(container, keyOrValue)`
- `remove(map, key)`
- `move_alloc(from, to)`
- `reshape(array, shape, [fill])`
- `pack(array, mask)`
- `unpack(vector, mask, fields)`

File helpers:
- `FileExists(name)`
- `FileSize(filename)`

## Built-In Objects

Database:
- `Connection`
- `RecordSet`
- `DDL`

File / e-mail / cookies:
- `File`
- `SMTP`
- `Cookie`

File object constructor and properties:
- `new File(FileName [, OpenMode])`
- Opens immediately and records any failure in `error`
- Default open mode is `r`
- Open modes mirror legacy `fopen` behavior: `r`, `r+`, `w`, `w+`, `a`, `a+`
- `name`, `mode`, `error`

Database methods and properties worth preserving:
- `Connection(...)` immediately attempts to connect
- Connections track open/last-used time and can auto-refresh when idle or too old
- `Connection.backend`, `Connection.opened`, `Connection.last_used`, `Connection.last_refresh`, `Connection.refresh_count`, and `Connection.stale`
- `RecordSet.execute()`, `next()`, `more()`, `rownum()`, `count()`, `eof()`, `value()`
- `DDL.execute()`
- `RecordSet.statement` and `DDL.statement`

File methods and properties worth preserving:
- `read([count])`
- `readln()`
- `write(data, [length])`
- `close()`
- `eof()`
- `rewind()`
- `read([count])` returns up to `count` bytes, or the whole remaining file when omitted or zero
- `read()` and `readln()` truncate at the first NUL byte
- `readln()` strips `\r` immediately before `\n`
- `write(data, [length])` returns bytes written
- `rewind()` resets read position only

Cookie object fields worth preserving:
- `name`
- `value`
- `expires`
- `path`
- `domain`
- `secure`

SMTP:
- `SMTP(host, [port])`
- `send(from, to, subject, body)`

## Database Model

Manual coverage is centered on MySQL, with later ODBC support.

Key database behaviors:
- `Connection` objects are constructed with a driver name and connection string
- Connection lifetimes are backend-managed, with idle/max-age policy parsed from the connection string when present
- Connection status is script-visible for debugging and diagnostics
- `RecordSet` is for statements that return rows
- `DDL` is for statements that do not return rows
- Parameter substitution supports:
  - Question marks: `?`
  - Host variables: `:name`
- `GRID` auto-executes a `RecordSet` if needed

## Web Semantics That Matter

Header timing is critical:
- `header()`, `SetCookie()`, and `redirect()` must happen before output starts
- Once output has started, those operations error out or become impossible

Request decoding:
- `Q()` and `F()` return already-decoded values
- `GetCookie()` also decodes URL-encoded cookie values

Include / jump:
- `INCLUDE` executes another file and returns to the caller
- `JUMP` transfers control and does not return
- Relative include search uses the current file location first, then `SHH_INCLUDE_PATH`

## Deployment Modes

Documented engine flavors:
- CGI executable
- Apache module
- IIS CGI
- IIS ISAPI
- Aprelium/Abyss Web Server hosting compatibility

## First Runtime Contract

The first Zig runtime shape should keep deployment, request, and response concerns separate:
- `DeploymentProfile` identifies the host flavor and server metadata
- `RequestContext` carries request facts only
- `ResponseState` tracks status, body start, and header mutability
- `Runtime` groups those pieces so CGI, Apache, and Abyss adapters can share one execution model
- Header-sensitive APIs should stay illegal after the body starts

## Response Semantics To Preserve

- `header()` mutates response metadata until headers are committed
- `SetCookie()` emits `Set-Cookie` response lines
- `redirect()` sets a 302 response and adds `Location`
- Header mutations stop once body output begins or headers are emitted
- Strict mode should reject silent coercion at those response boundaries

## CGI Adapter Notes

- The adapter should read CGI environment variables into deployment and request state
- `SERVER_SOFTWARE` can be used as a heuristic to distinguish Abyss and Apache module hosting
- The adapter should stay testable from an environment map before we wire a live process entrypoint

## File Naming

For this experiment, the preferred source-file extension is `.short`.

Legacy compatibility aliases can still be supported where useful:
- `.tran`
- `.shh`
- `.shl` if we want a thin transitional bridge

## Compatibility Priorities For A Rebuild

If we reimplement this, the order I would preserve is:
1. Parser and script delimiters
2. String / number / date coercion rules
3. Request, cookie, and header semantics
4. Control flow and function semantics
5. File and database object behavior
6. Deployment adapters and environment integration, including Aprelium/Abyss
7. Modern safety improvements as opt-in features, not defaults

Runtime features worth tracking separately from archived semantics:
- Optional strict typing for coercion-heavy code paths
- Safer HTML, header, and cookie emission boundaries
- Regex helpers as a separate feature rather than a silent replacement for string helpers
- Regex extraction helpers that return the first match or a named/numbered capture

## Manual Quirks To Treat Carefully

The manual itself contains a few likely doc typos and copy-paste errors, so the runtime should be verified by examples, not only by prose:
- `builtin.float.html` appears mislabeled or inconsistent
- `lang.dates.html` and `builtin.date.html` disagree on the lower bound wording
- Some leaf pages are blank placeholders
- Some examples contain obvious formatting / typo noise

That makes the older apps especially valuable: they can tell us what the engine actually did.

## Likely Next Step

Mine the older applications for:
- Real syntax usage
- Error handling patterns
- Header / cookie timing
- Database substitution edge cases
- Any behavior not captured cleanly in the manual

## Real App Evidence: `cart3.zip`

This shopping cart example is a very useful compatibility witness because it exercises the language in a realistic way.
The `.tran` extension appears to be this app's historical template/source naming choice, not a ShortHand language requirement.

Observed patterns:
- `include`-driven page composition
- Session creation with `Cookie` plus `SetCookie()`
- Random ID generation with `rand()`, `substring()`, and `length()`
- Request reads via `q()` and `f()`
- Response control with `redirect()` and `Exit()`
- MySQL access via `Connection`, `RecordSet`, and `DDL`
- Parameterized SQL via both `?` and string concatenation
- Field access like `cart.qty`, `cart.modelname`, `product.productimage`
- Pagination / slicing with `substring()` and `RecordSet.count`
- Search result highlighting with `replace()`
- Casting / formatting with `Int()` and `Float()`
- Page-state dispatch with `state` query parameters

Notable compatibility signals from the sample:
- Implicit globals are relied on heavily
- Variables are used before explicit initialization
- Cookie values double as UI configuration state
- Some SQL is parameterized, some is not, so the runtime must tolerate both legacy styles
- Output timing matters because the app uses headers, cookies, and redirects before emitting HTML

What this sample suggests for a faithful rebuild:
- Keep legacy coercion and truthiness behavior
- Preserve the old request/response timing rules
- Preserve permissive variable creation
- Treat legacy string handling as byte-oriented unless the modern mode explicitly opts in to UTF-8
