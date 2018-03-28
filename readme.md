# Simpl

> Pretty, simple, minimal, customizable and fast ZSH prompt based on @sindresorhus's [Pure](https://github.com/sindresorhus/pure)

<img src="screenshot.png" width="864">

## Screencast

<a href="https://asciinema.org/a/7td6jwaefjcnq23sta884t7wr" target="_blank"><img src="https://asciinema.org/a/7td6jwaefjcnq23sta884t7wr.png" /></a>

## Overview

Most prompts are cluttered, ugly and slow. I wanted something minimalist and
visually pleasing that stayed out of my way.

- Comes with the perfect prompt character.
  Author went through the whole Unicode range to find it.
- Shows `git` branch and whether it's dirty (with a `*`).
- Indicates when you have unpushed/unpulled `git` commits with up/down arrows. *(Check is done asynchronously!)*
- Prompt character turns red if the last command didn't exit with `0`.
- Command execution time will be displayed if it exceeds the set threshold.
- Username and host only displayed when in an SSH session.
- Shows the current path in the title and the [current folder & command](screenshot-title-cmd.png) when a process is running.
- Support VI-mode indication by reverse prompt symbol (Zsh 5.3+).
- Makes an excellent starting point for your own custom prompt.

### Description

My prompt consist of 3 parts, the main left-sided prompt just with a prompt
character so I have room for long commands, a pre-left-sided prompt to display
the main context (e.g. pwd and git info), and a right-sided prompt for
additional context that dissapears when text goes over it or line is accepted.

This structure makes it easy to read for me as I can identify easily the
executed commands and working directories through the scrollback buffer due to
its fixed position in the line. Since the right-sided prompt is splited in 2
lines it works well on small windows. This is perfect to me as I always end up
working with multiple tmux panes.

To keep it simple I just support the features I use on a daily basis, so this
prompt won't be cluttered with fancy battery indicators.

A prompt with all features:

```
~/dev/simpl on master* ⇡ 42s 4&
virtualenv ❱                                                 eduarbo at GlaDoS
```

Left prompt:

- `❱` is shown if you are a normal user. When root, a classic # will be shown instead
- `❱` will be `$SIMPL_PROMPT_SYMBOL_COLOR` if the last command exited successfully,
otherwise will be `$SIMPL_PROMPT_SYMBOL_FAIL_COLOR` (defaults to red)
- Displays python's virtualenv name before `❱` if activated

Pre left prompt:

- A short `pwd` version is shown
- Shows git branch and whether it's dirty (with a *)
- Indicates when you have unpushed/unpulled git commits with up/down arrows.
  (Check is done asynchronously!)
- Command execution time will be displayed if it exceeds the set threshold
  (default 5 seconds)
- Show number of background jobs (if any)

Right prompt:

- Username and host only displayed when in an SSH session or logged in as root


## Install

### Manually

1. Either…
  - Clone this repo
  - add it as a submodule, or
  - just download [`simpl.zsh`](simpl.zsh) and [`async.zsh`](async.zsh)

2. Symlink `simpl.zsh` to somewhere in [`$fpath`](https://www.refining-linux.org/archives/46-ZSH-Gem-12-Autoloading-functions.html) with the name `prompt_simpl_setup`.

3. Symlink `async.zsh` in `$fpath` with the name `async`.


## Options

| Option                           | Description                                                                                     | Default value  |
| :------------------------------- | :---------------------------------------------------------------------------------------------- | :------------- |
| **`SIMPL_CMD_MAX_EXEC_TIME`**     | The max execution time of a process before its run time is shown when it exits.                | `5` seconds    |
| **`SIMPL_GIT_PULL=0`**            | Prevents Simpl from checking whether the current Git remote has been updated.                  |                |
| **`SIMPL_GIT_UNTRACKED_DIRTY=0`** | Do not include untracked files in dirtiness check. Mostly useful on large repos (like WebKit). |                |
| **`SIMPL_GIT_DELAY_DIRTY_CHECK`** | Time in seconds to delay git dirty checking when `git status` takes > 5 seconds.               | `1800` seconds |
| **`SIMPL_PROMPT_SYMBOL`**         | Defines the prompt symbol.                                                                     | `❱`            |
| **`SIMPL_PROMPT_VICMD_SYMBOL`**   | Defines the prompt symbol used when the `vicmd` keymap is active (VI-mode).                    | `❰`            |
| **`SIMPL_GIT_DOWN_ARROW`**        | Defines the git down arrow symbol.                                                             | `⇣`            |
| **`SIMPL_GIT_UP_ARROW`**          | Defines the git up arrow symbol.                                                               | `⇡`            |

## Example

```sh
# .zshrc

autoload -U promptinit; promptinit

# optionally define some options
SIMPL_CMD_MAX_EXEC_TIME=10

prompt simpl
```


## Tips

In the screenshot you see Simpl running in [Hyper](https://hyper.is) with the [hyper-snazzy](https://github.com/sindresorhus/hyper-snazzy) theme and Menlo font.

The [Tomorrow Night Eighties](https://github.com/chriskempson/tomorrow-theme) theme with the [Droid Sans Mono](https://www.fontsquirrel.com/fonts/droid-sans-mono) font (15pt) is also a [nice combination](https://github.com/sindresorhus/pure/blob/95ee3e7618c6e2162a1e3cdac2a88a20ac3beb27/screenshot.png).<br>
*Just make sure you have anti-aliasing enabled in your terminal.*

To have commands colorized as seen in the screenshot, install [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).


## Integration

### [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)

1. Symlink (or copy) `simpl.zsh` to `~/.oh-my-zsh/custom/simpl.zsh-theme`.
2. Symlink (or copy) `async.zsh` to `~/.oh-my-zsh/custom/async.zsh`.
3. Set `ZSH_THEME="simpl"` in your `.zshrc` file.
4. Do not enable the following (incompatible) plugins: `vi-mode`, `virtualenv`.

**NOTE:** `oh-my-zsh` overrides the prompt so Simpl must be activated *after* `source $ZSH/oh-my-zsh.sh`.

### [antigen](https://github.com/zsh-users/antigen)

Update your `.zshrc` file with the following two lines (order matters). Do not use the `antigen theme` function.

```sh
antigen bundle mafredri/zsh-async
antigen bundle eduarbo/simpl
```

### [antibody](https://github.com/getantibody/antibody)

Update your `.zshrc` file with the following two lines (order matters):

```sh
antibody bundle mafredri/zsh-async
antibody bundle eduarbo/simpl
```

### [zplug](https://github.com/zplug/zplug)

Update your `.zshrc` file with the following two lines:

```sh
zplug mafredri/zsh-async, from:github
zplug eduarbo/simpl, use:simpl.zsh, from:github, as:theme
```

### [zplugin](https://github.com/zdharma/zplugin)

Update your `.zshrc` file with the following two lines (order matters):

```sh
zplugin ice pick"async.zsh" src"simpl.zsh"
zplugin light eduarbo/simpl
```

## FAQ

There are currently no FAQs.

See [FAQ Archive](https://github.com/sindresorhus/pure/wiki/FAQ-Archive) for previous FAQs.

## License

Simpl MIT © [Eduardo Ruiz](http://eduarbo.com) <br/>
Pure MIT © [Sindre Sorhus](https://sindresorhus.com)
