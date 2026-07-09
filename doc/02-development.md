# Development

Navigation: [Previous: Usage](01-usage.md) | [README](README.md)

This module intentionally has no Composer, Node, Python, or framework dependency. It uses Ruby's standard `socket` library to keep the process-web smoke test small and portable on macOS.

Run the local smoke test with:

```bash
tests/process-web-smoke.sh
```

Build the production zip from the meta workspace root:

```bash
./tools/dev2prod.sh process-web-demo-module
```

The production package is expected to include `manifest.json`, `server/app.rb`, and documentation.

Navigation: [Previous: Usage](01-usage.md) | [README](README.md)
