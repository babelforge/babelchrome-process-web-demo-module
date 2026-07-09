# Usage

Navigation: [README](README.md) | [Next: Development](02-development.md)

The module opens from:

```text
babelchrome://process-web-demo
```

Expected behavior:

- BabelChrome assigns a local port to the module process.
- BabelChrome starts `/usr/bin/ruby server/app.rb --port <assigned-port>`.
- The ExtensionHost waits for `/health`.
- BabelChrome proxies the stable route to the process `/index` path.
- The random local process port is not exposed as the stable browser URL.

Navigation: [README](README.md) | [Next: Development](02-development.md)
