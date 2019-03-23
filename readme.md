# Simpl

> Pretty, minimal, customizable and fast ZSH prompt based on
> @sindresorhus's [Pure](https://github.com/sindresorhus/pure)

<img src="screenshot.png" width="864">


## Screencast

<a href="https://asciinema.org/a/7td6jwaefjcnq23sta884t7wr" target="_blank"><img src="https://asciinema.org/a/7td6jwaefjcnq23sta884t7wr.png" /></a>


## Overview

Most prompts are cluttered, ugly and slow. I wanted something minimalist and
visually pleasing that stayed out of my way.

### Why?

- Comes with the perfect prompt character.
  Author went through the whole Unicode range to find it.
- Shows `git` branch and whether it's dirty (with a `*`).
- Indicates when you have unpushed/unpulled `git` commits with up/down arrows. *(Check is done asynchronously!)*
- Prompt character turns red if the last command didn't exit with `0`.
- Command execution time will be displayed if it exceeds the set threshold.
- Username and host only displayed when in an SSH session.
- Shows the current path in the title and the [current folder & command](screenshot-title-cmd.png) when a process is running.
- Makes an excellent starting point for your own custom prompt.


## Customization

Simpl supports customization using the following environment variables:

| Option                           | Description                                                                                     | Default value  |
| :------------------------------- | :---------------------------------------------------------------------------------------------- | :------------- |
| **`SIMPL_CMD_MAX_EXEC_TIME`**     | The max execution time of a process before its run time is shown when it exits.                | `5` seconds    |
| **`SIMPL_GIT_PULL=0`**            | Prevents Simpl from checking whether the current Git remote has been updated.                  |                |
| **`SIMPL_GIT_UNTRACKED_DIRTY=0`** | Do not include untracked files in dirtiness check. Mostly useful on large repos (like WebKit). |                |
| **`SIMPL_GIT_DELAY_DIRTY_CHECK`** | Time in seconds to delay git dirty checking when `git status` takes > 5 seconds.               | `1800` seconds |
| **`SIMPL_PROMPT_SYMBOL`**         | Defines the prompt symbol.                                                                     | `❱`            |
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


## Install

### Manually

1. Either…
  - Clone this repo
  - add it as a submodule, or
  - just download [`simpl.zsh`](simpl.zsh) and [`async.zsh`](async.zsh)

2. Symlink `simpl.zsh` to somewhere in [`$fpath`](http://www.refining-linux.org/archives/46/ZSH-Gem-12-Autoloading-functions/) with the name `prompt_simpl_setup`.

3. Symlink `async.zsh` in `$fpath` with the name `async`.

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


## Tips

In the screenshot you see Simpl running in [iTerm2](https://www.iterm2.com/) with a custom theme and [Hack](https://sourcefoundry.org/hack/) font.

To have commands colorized as seen in the screenshot, install [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).


## License

Simpl MIT © [Eduardo Ruiz](http://eduarbo.com) <br/>
Pure MIT © [Sindre Sorhus](https://sindresorhus.com)
