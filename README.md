# Process Web Demo Module

`babelforge.process-web-demo` is an installable BabelChrome module used to validate the `process-web` runtime contract.

It runs a tiny Ruby HTTP process through the standard library only. BabelChrome owns the stable route and assigned port; the module owns the local process.

## Documentation

Public documentation starts at [doc/README.md](doc/README.md).

## Quality

```bash
tests/process-web-smoke.sh
```
