# Tools

---

Tools are defined as pre-built assets that influence the supply chain but are not included in the software bill of materials. Examples:

- Git
- Bazelisk
- Compilers, linkers, etc.
- Formatters, linters, and other static analysis tools
- Debuggers, profilers, etc.
- `jq`, `rg`, `kubectl`, and other developer tools
- ...

This directory contains shared resources for tools that our images use.

## DotSlash

The `dotslash` subdirectory contains resources for [DotSlash](https://dotslash-cli.com/docs/), which we use to securely manage tools that do not require building from source.
