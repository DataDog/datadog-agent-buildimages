# Agent developer environments

-----

This directory contains the environments used by all Agent developers, both internal and external. The environments are based on the build images themselves.

***Table of contents***

- [Utilities](#utilities)
- [Git extensions](#git-extensions)
- [Repositories](#repositories)
- [Shells](#shells)
- [Fonts](#fonts)
- [Ports](#ports)

## Utilities

This is a non-exhaustive list of utilities that are available in every image:

- [`ambr`](https://github.com/dalance/amber) - find and replace like `sed` but with interactivity
- [`bat`](https://github.com/sharkdp/bat) - show file contents like `cat`
- [`btm`](https://github.com/ClementTsang/bottom) - system monitor like `top`
- [`eza`](https://github.com/eza-community/eza) - list files like `ls`
- [`fd`](https://github.com/sharkdp/fd) - find files like `find`
- [`fzf`](https://github.com/junegunn/fzf) - fuzzy finder
- [`gfold`](https://github.com/nickgerace/gfold) - Git status viewer for multiple repositories
- [`hyperfine`](https://github.com/sharkdp/hyperfine) - benchmarking tool
- [`gitui`](https://github.com/extrawurst/gitui) - Git terminal UI
- [`jq`](https://github.com/jqlang/jq) - JSON processor
- [`pdu`](https://github.com/KSXGitHub/parallel-disk-usage) - show disk usage like `du`
- [`procs`](https://github.com/dalance/procs) - process viewer like `ps`
- [`rg`](https://github.com/BurntSushi/ripgrep) - search file contents like `grep`
- [`yazi`](https://github.com/sxyazi/yazi) - file manager UI

## Git extensions

Each of the following subcommands are available via `git <subcommand> ...` in every image:

- `dd-clone` - Performs a shallow clone [^1] of a Datadog repository to the proper managed location. The first argument is the repository name and a second optional argument is the branch name. Example invocations:
    - `git dd-clone datadog-agent`
    - `git dd-clone datadog-agent user/feature`
- `dd-switch` - Emulates the behavior of `git switch` but smart enough to handle shallow clones. The branch name is the only argument.

## Repositories

Every image assumes repositories will be cloned to `~/repos`. The `dd-clone` Git extension will clone repositories to this location and `gfold` is pre-configured to look for repositories in this location.

## Shells

Images come with shells based on their platform e.g. [Zsh](https://www.zsh.org) for Linux and [PowerShell](https://github.com/PowerShell/PowerShell) for Windows. All shells are pre-configured with at least [Starship](https://github.com/starship/starship) prompt.

Every image comes with [Nushell](https://github.com/nushell/nushell).

## Fonts

Every image comes with the following fonts:

- [FiraCode](https://github.com/ryanoasis/nerd-fonts)
- [CascadiaCode](https://github.com/microsoft/cascadia-code)

All fonts have [Nerd Font](https://www.nerdfonts.com) glyphs, and [Noto Emoji](https://github.com/googlefonts/noto-emoji) is installed for emoji support.

## Ports

Every image exposes port 22 for SSH access.

[^1]: A shallow clone by default matches our use case of ephemeral developer environments. If persistence is desired then developers can easily convert the shallow clone to a full clone by running `git fetch --unshallow`. More information:
    - [Git clone: a data-driven study on cloning behaviors](https://github.blog/open-source/git/git-clone-a-data-driven-study-on-cloning-behaviors/)
    - [Get up to speed with partial clone and shallow clone](https://github.blog/open-source/git/get-up-to-speed-with-partial-clone-and-shallow-clone/)
