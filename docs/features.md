# ShortHand Feature Reference

This page documents the runtime features in the Zig revival. The archived manual in `docs/manual/` remains the historical reference for the original language and deployment docs.

## Language Model

- Script blocks still use the archived ShortHand delimiters
- The runtime keeps the manual-faithful core as the compatibility baseline
- Strict typing is opt-in and does not replace the legacy coercion model by default
- `[]` is the only indexing syntax
- Dense arrays are 1-based
- Associative maps use string keys

## Containers

The current runtime includes array and map containers with Fortran-style allocation management:

- `new Array(...)`
- `new Map(...)`
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

## Regex

Regex helpers are regular runtime functions, not replacements for the manual string helpers:

- `regexmatch(pattern, subject)`
- `regexvalid(pattern)`
- `regexreplace(pattern, replacement, subject)`
- `regexextract(pattern, subject, [group])`
- `preg_match(pattern, subject)` alias
- `preg_replace(pattern, replacement, subject)` alias
- `regexcapture(pattern, subject, [group])` alias

## Text, Date, And Numeric Helpers

The runtime currently ships with the familiar helper set from the manual, plus the new regex and container surface:

- `string`, `int`, `float`, `format`
- `replace`, `translate`, `strpos`, `substring`
- `length`, `lc`, `uc`
- `date`, `FormatDate`, `now`, `AddHours`, `AddMinutes`, `AddSeconds`
- `max`, `min`, `rand`

## Request, Response, And Deployment

- CGI-style execution is the baseline
- Apache and Aprelium/Abyss are first-class deployment targets
- `header()`, `SetCookie()`, and `redirect()` still obey response timing rules
- Strict mode hardens response-boundary coercion

## Data Layer

- `Connection(driver, connection_string)` records the requested driver name and connection string
- The connection string can carry lifecycle policy hints like `backend=`, `driver=`, `auto_refresh=`, `reconnect=`, `idle_timeout=`, and `max_age=`
- `Connection.backend`, `Connection.opened`, `Connection.last_used`, `Connection.last_refresh`, `Connection.refresh_count`, and `Connection.stale` expose that lifecycle state to scripts
- `RecordSet.execute()` and `DDL.execute()` consult the connection freshness contract before they run
- The current build routes `sqlite` to the SQLite adapter and falls back to the bundled legacy compatibility backend for other labels; the interface is shaped so ShovelerDB, PostgreSQL, MySQL, ODBC, and Mongo adapters can plug in later

## Objects

- `File`
- `Cookie`
- `Connection`
- `RecordSet`
- `DDL`
- `SMTP`

The archived manual still covers the legacy object model and the compatibility rules around those types. The newer runtime keeps the same surface, but lets the backend manage connection freshness behind `Connection`.
