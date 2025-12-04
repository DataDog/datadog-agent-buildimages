# DotSlash

---

We use [DotSlash](https://dotslash-cli.com/docs/) to securely manage tools that do not require building from source. See its [motivation](https://dotslash-cli.com/docs/motivation/) for more details.

## Configuration

The `dotslash/config` subdirectory contains a JSON file for each tool that adheres to the [schema](https://dotslash-cli.com/docs/dotslash-file/) of a DotSlash file payload. Each file also defines a top-level `__extra_metadata` field that contains additional metadata, such as the tool's uncompressed size on each platform.

```json
{
  "__extra_metadata": {
    "platforms": {
      "linux-aarch64": {
        "uncompressed_size": 1234567
      },
      ...
    }
  },
  "name": "jq",
  "platforms": {
    "linux-aarch64": { ... },
    ...
  }
}
```

## Generation

The `dotslash/generate.py` script is used at build time to generate DotSlash files for each tool with, to save space, only support for the target system and architecture.

```
❯ python tools/dotslash/generate.py --help
usage: generate.py [-h] --config-dir CONFIG_DIR --output-dir OUTPUT_DIR [--tools TOOLS] [--tools-file TOOLS_FILE]

Generate DotSlash files from tool configuration

options:
  -h, --help            show this help message and exit
  --config-dir CONFIG_DIR
                        Path to the directory containing tool configuration
  --output-dir OUTPUT_DIR
                        Path to the directory for generated DotSlash files
  --tools TOOLS         A comma-separated list of tools to generate
  --tools-file TOOLS_FILE
                        The path to a file containing a newline-separated list of tools to generate
```

If neither of the (mutually exclusive) `--tools` nor `--tools-file` options are selected, all tools that are available for the target platform will be processed.

## Management

The `dda run tools check` command can be used to check the correctness and integrity of the tool configurations. The `--fix` option can be used to fix any errors found. By default, only the schema and file formatting are checked.

```
❯ dda run tools check
Validated tool schemas: 19
```

The `--integrity` option can be used to check the integrity of the tool configurations. This will temporarily fetch every possible artifact in order to perform checks such as comparing the sizes and hash digests against the expected values and ensuring the presence of the expected paths to binaries.

```
❯ dda run tools check --integrity
┏━━━━━━━━━━━━━━━┳━━━━━━━━━━━┓
┃ Platform      ┃ Artifacts ┃
┡━━━━━━━━━━━━━━━╇━━━━━━━━━━━┩
│ linux-aarch64 │ 17        │
│ linux-x86_64  │ 19        │
└───────────────┴───────────┘
Failed tools:
  rg:
    linux-aarch64:
      Artifact #1:
        Digest mismatch:
          Expected: 4cf9f2741e6c465ffdb7c26f38056a59e2a2544b51f7cc128ef28337eeae4d8e
          Actual: c827481c4ff4ea10c9dc7a4022c8de5db34a5737cb74484d62eb94a95841ab2f
        Size mismatch:
          Expected: 1234567
          Actual: 2047405
    linux-x86_64:
      Artifact #1:
        Uncompressed size mismatch:
          Expected: 1234567
          Actual: 6961825
```

The `--force` option must be used to trust providers for integrity fixes.

```
❯ dda run tools check --integrity --fix --force
┏━━━━━━━━━━━━━━━┳━━━━━━━━━━━┓
┃ Platform      ┃ Artifacts ┃
┡━━━━━━━━━━━━━━━╇━━━━━━━━━━━┩
│ linux-aarch64 │ 17        │
│ linux-x86_64  │ 19        │
└───────────────┴───────────┘
Fixed tools/dotslash/config/rg.json
```

## Auditing

The `dda run tools info` command can be used to display detailed statistics about all of the defined tools.

```
❯ dda run tools info
┏━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┓
┃ Platform      ┃ Artifacts        ┃ Size                          ┃ Providers     ┃ Artifact Formats ┃ Hash Algorithms ┃
┡━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━┩
│ linux-aarch64 │ ┌─────────┬────┐ │ ┌──────────────┬────────────┐ │ ┌──────┬────┐ │ ┌────────┬────┐  │ ┌────────┬────┐ │
│               │ │ defined │ 17 │ │ │ compressed   │ 100.87 MiB │ │ │ http │ 17 │ │ │ plain  │ 3  │  │ │ blake3 │ 17 │ │
│               │ │ sources │ 17 │ │ │ uncompressed │ 144.74 MiB │ │ └──────┴────┘ │ │ tar.gz │ 11 │  │ └────────┴────┘ │
│               │ └─────────┴────┘ │ └──────────────┴────────────┘ │               │ │ zip    │ 3  │  │                 │
│               │                  │                               │               │ └────────┴────┘  │                 │
│ linux-x86_64  │ ┌─────────┬────┐ │ ┌──────────────┬────────────┐ │ ┌──────┬────┐ │ ┌────────┬────┐  │ ┌────────┬────┐ │
│               │ │ defined │ 19 │ │ │ compressed   │ 114.95 MiB │ │ │ http │ 19 │ │ │ plain  │ 3  │  │ │ blake3 │ 19 │ │
│               │ │ sources │ 19 │ │ │ uncompressed │ 178.63 MiB │ │ └──────┴────┘ │ │ tar.gz │ 11 │  │ └────────┴────┘ │
│               │ └─────────┴────┘ │ └──────────────┴────────────┘ │               │ │ zip    │ 5  │  │                 │
│               │                  │                               │               │ └────────┴────┘  │                 │
└───────────────┴──────────────────┴───────────────────────────────┴───────────────┴──────────────────┴─────────────────┘
```

The `--json` flag can be used to output the information in JSON format. Note that this will include entries for all platforms even if no tools are available for that platform.
