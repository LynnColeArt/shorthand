# Apache Integration Harness

This directory holds a local Apache 2.4 integration setup for ShortHand.

The goal is to exercise the runtime through a real Apache CGI request using a `.short` file with a shebang that points at `zig-out/bin/short run`.

## What It Tests

- Apache can execute a ShortHand CGI page directly
- The runtime strips the shebang line before parsing
- Headers are emitted before the response body
- The script can use the normal ShortHand runtime surface, including arrays and maps

## Files

- `hello.short`: sample ShortHand CGI page
- `httpd.conf.in`: Apache config template for local use
- `test.sh`: end-to-end harness that builds the binary, starts Apache, fetches the page, and validates the response
- `site/`: browser-ready virtual host with a start/stop wrapper
- `site/counter.short`: cookie-backed visit counter demo
- `site/echo.short`: POST echo demo
- `site/redirect.short`: redirect bounce demo
- `site/redirect-complete.short`: redirect landing page
- `site/search.short`: regex search demo with validity and no-hit states

## Requirements

- Apache 2.4
- `curl`
- `zig`

## Run

```bash
./apache/test.sh
```

The harness uses a temporary server root and does not modify system Apache configuration.

## Browser Site

If you want to open the sample in a browser, start the local virtual host:

```bash
./apache/site/start.sh
```

Then visit:

- `http://shorthand.localhost:18081/`
- `http://localhost:18081/`
- `http://shorthand.localhost:18081/counter.short`
- `http://shorthand.localhost:18081/echo.short`
- `http://shorthand.localhost:18081/redirect.short`
- `http://shorthand.localhost:18081/redirect-complete.short`
- `http://shorthand.localhost:18081/search.short`

Stop it when you are done:

```bash
./apache/site/stop.sh
```
