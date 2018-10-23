# Simpl
# by Eduardo Ruiz
# https://github.com/eduarbo/simpl
# MIT License

# Simpl theme heavily inspired by Sindre Sorhus' Pure theme
# https://github.com/sindresorhus/pure

# For my own and others sanity
# git:
# %b => current branch
# %a => current action (rebase/merge)

# prompt:
# %B => Start boldface mode.
# %b => Stop boldface mode.
# %U => Start underline mode.
# %u => Stop underline mode.
# %S => Start standout mode.
# %s => Stop standout mode.
# %K => Start using a different bacKground colour. The syntax is identical to
#       that for %F and %f.
# %k => Stop using a different bacKground colour.
# %F => Start using a different foreground colour, if supported by the terminal.
#       The colour may be specified two ways: either as a numeric argument, as
#       normal, or by a sequence in braces following the %F, for example
#       %F{red}. In the latter case the values allowed are as described for the
#       fg zle_highlight attribute; Character Highlighting. This means that
#       numeric colours are allowed in the second format also.
# %f => Reset foreground color.
# %~ => current path
# %* => time
# %n => username
# %m => shortname host

# Conditional Substrings in Prompts:
# %(x.true-text.false-text) => Specifies a ternary expression

#   The left parenthesis may be preceded or followed by a positive integer n,
#   which defaults to zero. A negative integer will be multiplied by -1. The
#   test character x may be any of the following:
#   ! => True if the shell is running with privileges
#   ? => True if the exit status of the last command was n
#   # => True if the effective uid of the current process is n

# terminal codes:
# \e7   => save cursor position
# \e[2A => move cursor 2 lines up
# \e[1G => go to position 1 in terminal
# \e8   => restore cursor position
# \e[K  => clears everything after the cursor on the current line
# \e[2K => clear everything on the current line

# Configuration
SIMPL_PREPOSITION_COLOR="${SIMPL_PREPOSITION_COLOR:-"%F{8}"}"

SIMPL_USER_COLOR="${SIMPL_USER_COLOR:-"%F{yellow}"}"
SIMPL_USER_ROOT_COLOR="${SIMPL_USER_ROOT_COLOR:-"%B%F{red}"}"
SIMPL_HOST_COLOR="${SIMPL_HOST_COLOR:-"%B%F{yellow}"}"
SIMPL_HOST_SYMBOL_COLOR="${SIMPL_HOST_SYMBOL_COLOR:-"%F{yellow}"}"
SIMPL_USER_HOST_PREPOSITION="${SIMPL_USER_HOST_PREPOSITION:-"${SIMPL_PREPOSITION_COLOR} at "}"

SIMPL_DIR_COLOR="${SIMPL_DIR_COLOR:-"%F{14}"}"

SIMPL_GIT_BRANCH_COLOR="${SIMPL_GIT_BRANCH_COLOR:-"%F{10}"}"
SIMPL_GIT_ARROW_COLOR="${SIMPL_GIT_ARROW_COLOR:-"%F{12}"}"
SIMPL_GIT_DIRTY_SYMBOL="${SIMPL_GIT_DIRTY_SYMBOL:-*}"
SIMPL_GIT_UP_ARROW="${SIMPL_GIT_UP_ARROW:-⇡}"
SIMPL_GIT_DOWN_ARROW="${SIMPL_GIT_DOWN_ARROW:-⇣}"
SIMPL_GIT_UNTRACKED_DIRTY="${SIMPL_GIT_UNTRACKED_DIRTY:-1}"
SIMPL_GIT_DELAY_DIRTY_CHECK="${SIMPL_GIT_DELAY_DIRTY_CHECK:-1800}"
SIMPL_GIT_PULL="${SIMPL_GIT_PULL:-1}"

SIMPL_VENV_COLOR="${SIMPL_VENV_COLOR:-"%F{magenta}"}"

SIMPL_PROMPT_SYMBOL="${SIMPL_PROMPT_SYMBOL:-❱}"
SIMPL_PROMPT_ROOT_SYMBOL="${SIMPL_PROMPT_ROOT_SYMBOL:-#}"
SIMPL_PROMPT_SYMBOL_COLOR="${SIMPL_PROMPT_SYMBOL_COLOR:-"%F{yellow}"}"
SIMPL_PROMPT_SYMBOL_ERROR_COLOR="${SIMPL_PROMPT_SYMBOL_ERROR_COLOR:-"%F{red}"}"
SIMPL_PROMPT2_SYMBOL_COLOR="${SIMPL_PROMPT2_SYMBOL_COLOR:-"%F{8}"}"

SIMPL_PROMPT_VICMD_SYMBOL="${SIMPL_PROMPT_VICMD_SYMBOL:-❰}"

SIMPL_CMD_MAX_EXEC_TIME="${SIMPL_CMD_MAX_EXEC_TIME:=1}"
SIMPL_EXEC_TIME_COLOR="${SIMPL_EXEC_TIME_COLOR:-"%F{8}"}"
SIMPL_JOBS_COLOR="${SIMPL_JOBS_COLOR:-"%F{8}"}"

# PROMPT_SIMPL_HOSTNAME_SYMBOL_MAP="${PROMPT_SIMPL_HOSTNAME_SYMBOL_MAP}"

# Utils
cl="%f%s%u%k%b"

# turns seconds into human readable time
# 165392 => 1d 21h 56m 32s
# https://github.com/sindresorhus/pretty-time-zsh
prompt_simpl_human_time_to_var() {
	local human total_seconds=$1 var=$2
	local days=$(( total_seconds / 60 / 60 / 24 ))
	local hours=$(( total_seconds / 60 / 60 % 24 ))
	local minutes=$(( total_seconds / 60 % 60 ))
	local seconds=$(( total_seconds % 60 ))
	(( days > 0 )) && human+="${days}d "
	(( hours > 0 )) && human+="${hours}h "
	(( minutes > 0 )) && human+="${minutes}m "
	human+="${seconds}s"

	# store human readable time in variable as specified by caller
	typeset -g "${var}"="${human}"
}

# stores (into prompt_simpl_cmd_exec_time) the exec time of the last command if set threshold was exceeded
prompt_simpl_check_cmd_exec_time() {
	integer elapsed
	(( elapsed = EPOCHSECONDS - ${prompt_simpl_cmd_timestamp:-$EPOCHSECONDS} ))
	typeset -g prompt_simpl_cmd_exec_time=
	(( elapsed > ${SIMPL_CMD_MAX_EXEC_TIME} )) && {
		prompt_simpl_human_time_to_var $elapsed "prompt_simpl_cmd_exec_time"
	}
}

prompt_simpl_set_title() {
	setopt localoptions noshwordsplit

	# emacs terminal does not support settings the title
	(( ${+EMACS} )) && return

	case $TTY in
		# Don't set title over serial console.
		/dev/ttyS[0-9]*) return;;
	esac

	# Show hostname if connected via ssh.
	local hostname=
	if [[ -n $prompt_simpl_state[username] ]]; then
		# Expand in-place in case ignore-escape is used.
		hostname="${(%):-(%m) }"
	fi

	local -a opts
	case $1 in
		expand-prompt) opts=(-P);;
		ignore-escape) opts=(-r);;
	esac

	# Set title atomically in one print statement so that it works
	# when XTRACE is enabled.
	print -n $opts $'\e]0;'${hostname}${2}$'\a'
}

prompt_simpl_preexec() {
	if [[ -n $prompt_simpl_git_fetch_pattern ]]; then
		# detect when git is performing pull/fetch (including git aliases).
		local -H MATCH MBEGIN MEND match mbegin mend
		if [[ $2 =~ (git|hub)\ (.*\ )?($prompt_simpl_git_fetch_pattern)(\ .*)?$ ]]; then
			# we must flush the async jobs to cancel our git fetch in order
			# to avoid conflicts with the user issued pull / fetch.
			async_flush_jobs 'prompt_simpl'
		fi
	fi

	typeset -g prompt_simpl_cmd_timestamp=$EPOCHSECONDS

	# shows the current dir and executed command in the title while a process is active
	prompt_simpl_set_title 'ignore-escape' "$PWD:t: $2"

	# Disallow python virtualenv from updating the prompt, set it to 12 if
	# untouched by the user to indicate that Simpl modified it. Here we use
	# magic number 12, same as in psvar.
	export VIRTUAL_ENV_DISABLE_PROMPT=${VIRTUAL_ENV_DISABLE_PROMPT:-12}
}

prompt_simpl_preprompt_render() {
	setopt localoptions noshwordsplit

	local on="${SIMPL_PREPOSITION_COLOR}on${cl}"

	# Set color for git branch/dirty status, change color if dirty checking has
	# been delayed.
	local branch_color="${SIMPL_GIT_BRANCH_COLOR}"
	[[ -n ${prompt_simpl_git_last_dirty_check_timestamp+x} ]] && branch_color="${cl}%F{red}"

	# Initialize the preprompt array.
	local -a preprompt_parts

	# Username and machine, if applicable.
	[[ -n $prompt_simpl_state[username] ]] && preprompt_parts+=("${prompt_simpl_state[username]}")

	# Set the path.
	preprompt_parts+=("${SIMPL_DIR_COLOR}%~${cl}")

	# Add git branch and dirty status info.
	typeset -gA prompt_simpl_vcs_info
	if [[ -n $prompt_simpl_vcs_info[branch] ]]; then
		preprompt_parts+=("${on} ${branch_color}${prompt_simpl_vcs_info[branch]}${prompt_simpl_git_dirty}${cl}")
	fi
	# Git pull/push arrows.
	if [[ -n $prompt_simpl_git_arrows ]]; then
		preprompt_parts+=("${SIMPL_GIT_ARROW_COLOR}${prompt_simpl_git_arrows}${cl}")
	fi

	# display number of jobs in background
	preprompt_parts+=("${SIMPL_JOBS_COLOR}%(1j.%j&.)${cl}")

	# Execution time.
	[[ -n $prompt_simpl_cmd_exec_time ]] && preprompt_parts+=("${SIMPL_EXEC_TIME_COLOR}${prompt_simpl_cmd_exec_time}${cl}")

	local cleaned_ps1=$PROMPT
	local -H MATCH MBEGIN MEND
	if [[ $PROMPT = *$prompt_newline* ]]; then
		# Remove everything from the prompt until the newline. This
		# removes the preprompt and only the original PROMPT remains.
		cleaned_ps1=${PROMPT##*${prompt_newline}}
	fi
	unset MATCH MBEGIN MEND

	# Construct the new prompt with a clean preprompt.
	local -ah ps1
	ps1=(
		${(j. .)preprompt_parts}  # Join parts, space separated.
		$prompt_newline           # Separate preprompt and prompt.
		$cleaned_ps1
	)

	PROMPT="${(j..)ps1}"

	# Expand the prompt for future comparision.
	local expanded_prompt
	expanded_prompt="${(S%%)PROMPT}"

	if [[ $1 == precmd ]]; then
		# Initial newline, for spaciousness.
		print
	elif [[ $prompt_simpl_last_prompt != $expanded_prompt ]]; then
		# Redraw the prompt.
		zle && zle .reset-prompt
	fi

	typeset -g prompt_simpl_last_prompt=$expanded_prompt
}

prompt_simpl_precmd() {
	# check exec time and store it in a variable
	prompt_simpl_check_cmd_exec_time
	unset prompt_simpl_cmd_timestamp

	# shows the full path in the title
	prompt_simpl_set_title 'expand-prompt' '%~'

	# preform async git dirty check and fetch
	prompt_simpl_async_tasks

	# Check if we should display the virtual env, we use a sufficiently high
	# index of psvar (12) here to avoid collisions with user defined entries.
	psvar[12]=
	# Check if a conda environment is active and display it's name
	if [[ -n $CONDA_DEFAULT_ENV ]]; then
		psvar[12]="${CONDA_DEFAULT_ENV//[$'\t\r\n']}"
	fi
	# When VIRTUAL_ENV_DISABLE_PROMPT is empty, it was unset by the user and
	# Simpl should take back control.
	if [[ -n $VIRTUAL_ENV ]] && [[ -z $VIRTUAL_ENV_DISABLE_PROMPT || $VIRTUAL_ENV_DISABLE_PROMPT = 12 ]]; then
		psvar[12]="${VIRTUAL_ENV:t}"
		export VIRTUAL_ENV_DISABLE_PROMPT=12
	fi

	# print the preprompt
	prompt_simpl_preprompt_render "precmd"

	if [[ -n $ZSH_THEME ]]; then
		print "WARNING: Oh My Zsh themes are enabled (ZSH_THEME='${ZSH_THEME}'). Simpl might not be working correctly."
		print "For more information, see: https://github.com/eduarbo/simpl#oh-my-zsh"
		unset ZSH_THEME  # Only show this warning once.
	fi
}

prompt_simpl_async_git_aliases() {
	setopt localoptions noshwordsplit
	local -a gitalias pullalias

	# list all aliases and split on newline.
	gitalias=(${(@f)"$(command git config --get-regexp "^alias\.")"})
	for line in $gitalias; do
		parts=(${(@)=line})           # split line on spaces
		aliasname=${parts[1]#alias.}  # grab the name (alias.[name])
		shift parts                   # remove aliasname

		# check alias for pull or fetch (must be exact match).
		if [[ $parts =~ ^(.*\ )?(pull|fetch)(\ .*)?$ ]]; then
			pullalias+=($aliasname)
		fi
	done

	print -- ${(j:|:)pullalias}  # join on pipe (for use in regex).
}

prompt_simpl_async_vcs_info() {
	setopt localoptions noshwordsplit

	# configure vcs_info inside async task, this frees up vcs_info
	# to be used or configured as the user pleases.
	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:*' use-simple true
	# only export two msg variables from vcs_info
	zstyle ':vcs_info:*' max-exports 2
	# export branch (%b) and git toplevel (%R)
	zstyle ':vcs_info:git*' formats '%b' '%R'
	zstyle ':vcs_info:git*' actionformats '%b|%a' '%R'

	vcs_info

	local -A info
	info[pwd]=$PWD
	info[top]=$vcs_info_msg_1_
	info[branch]=$vcs_info_msg_0_

	print -r - ${(@kvq)info}
}

# fastest possible way to check if repo is dirty
prompt_simpl_async_git_dirty() {
	setopt localoptions noshwordsplit
	local untracked_dirty=$1

	if [[ $untracked_dirty = 0 ]]; then
		command git diff --no-ext-diff --quiet --exit-code
	else
		test -z "$(command git status --porcelain --ignore-submodules -unormal)"
	fi

	return $?
}

prompt_simpl_async_git_fetch() {
	setopt localoptions noshwordsplit

	# set GIT_TERMINAL_PROMPT=0 to disable auth prompting for git fetch (git 2.3+)
	export GIT_TERMINAL_PROMPT=0
	# set ssh BachMode to disable all interactive ssh password prompting
	export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-"ssh"} -o BatchMode=yes"

	# Default return code, indicates Git fetch failure.
	local fail_code=99

	# Guard against all forms of password prompts. By setting the shell into
	# MONITOR mode we can notice when a child process prompts for user input
	# because it will be suspended. Since we are inside an async worker, we
	# have no way of transmitting the password and the only option is to
	# kill it. If we don't do it this way, the process will corrupt with the
	# async worker.
	setopt localtraps monitor

	# Make sure local HUP trap is unset to allow for signal propagation when
	# the async worker is flushed.
	trap - HUP

	trap '
		# Unset trap to prevent infinite loop
		trap - CHLD
		if [[ $jobstates = suspended* ]]; then
			# Set fail code to password prompt and kill the fetch.
			fail_code=98
			kill %%
		fi
	' CHLD

	command git -c gc.auto=0 fetch >/dev/null &
	wait $! || return $fail_code

	unsetopt monitor

	# check arrow status after a successful git fetch
	prompt_simpl_async_git_arrows
}

prompt_simpl_async_git_arrows() {
	setopt localoptions noshwordsplit
	command git rev-list --left-right --count HEAD...@'{u}'
}

prompt_simpl_async_tasks() {
	setopt localoptions noshwordsplit

	# initialize async worker
	((!${prompt_simpl_async_init:-0})) && {
		async_start_worker "prompt_simpl" -u -n
		async_register_callback "prompt_simpl" prompt_simpl_async_callback
		typeset -g prompt_simpl_async_init=1
	}

	# Update the current working directory of the async worker.
	async_worker_eval "prompt_simpl" builtin cd -q $PWD

	typeset -gA prompt_simpl_vcs_info

	local -H MATCH MBEGIN MEND
	if [[ $PWD != ${prompt_simpl_vcs_info[pwd]}* ]]; then
		# stop any running async jobs
		async_flush_jobs "prompt_simpl"

		# reset git preprompt variables, switching working tree
		unset prompt_simpl_git_dirty
		unset prompt_simpl_git_last_dirty_check_timestamp
		unset prompt_simpl_git_arrows
		unset prompt_simpl_git_fetch_pattern
		prompt_simpl_vcs_info[branch]=
		prompt_simpl_vcs_info[top]=
	fi
	unset MATCH MBEGIN MEND

	async_job "prompt_simpl" prompt_simpl_async_vcs_info

	# # only perform tasks inside git working tree
	[[ -n $prompt_simpl_vcs_info[top] ]] || return

	prompt_simpl_async_refresh
}

prompt_simpl_async_refresh() {
	setopt localoptions noshwordsplit

	if [[ -z $prompt_simpl_git_fetch_pattern ]]; then
		# we set the pattern here to avoid redoing the pattern check until the
		# working three has changed. pull and fetch are always valid patterns.
		typeset -g prompt_simpl_git_fetch_pattern="pull|fetch"
		async_job "prompt_simpl" prompt_simpl_async_git_aliases
	fi

	async_job "prompt_simpl" prompt_simpl_async_git_arrows

	# do not preform git fetch if it is disabled or in home folder.
	if (( ${SIMPL_GIT_PULL} )) && [[ $prompt_simpl_vcs_info[top] != $HOME ]]; then
		# tell worker to do a git fetch
		async_job "prompt_simpl" prompt_simpl_async_git_fetch
	fi

	# if dirty checking is sufficiently fast, tell worker to check it again, or wait for timeout
	integer time_since_last_dirty_check=$(( EPOCHSECONDS - ${prompt_simpl_git_last_dirty_check_timestamp:-0} ))
	if (( time_since_last_dirty_check > ${SIMPL_GIT_DELAY_DIRTY_CHECK} )); then
		unset prompt_simpl_git_last_dirty_check_timestamp
		# check check if there is anything to pull
		async_job "prompt_simpl" prompt_simpl_async_git_dirty ${SIMPL_GIT_UNTRACKED_DIRTY}
	fi
}

prompt_simpl_check_git_arrows() {
	setopt localoptions noshwordsplit
	local arrows left=${1:-0} right=${2:-0}

	(( right > 0 )) && arrows+=${SIMPL_GIT_DOWN_ARROW}
	(( left > 0 )) && arrows+=${SIMPL_GIT_UP_ARROW}

	[[ -n $arrows ]] || return
	typeset -g REPLY=$arrows
}

prompt_simpl_async_callback() {
	setopt localoptions noshwordsplit
	local job=$1 code=$2 output=$3 exec_time=$4 next_pending=$6
	local do_render=0

	case $job in
		\[async])
			# code is 1 for corrupted worker output and 2 for dead worker
			if [[ $code -eq 2 ]]; then
				# our worker died unexpectedly
				typeset -g prompt_pure_async_init=0
			fi
			;;
		prompt_simpl_async_vcs_info)
			local -A info
			typeset -gA prompt_simpl_vcs_info

			# parse output (z) and unquote as array (Q@)
			info=("${(Q@)${(z)output}}")
			local -H MATCH MBEGIN MEND
			if [[ $info[pwd] != $PWD ]]; then
				# The path has changed since the check started, abort.
				return
			fi
			# check if git toplevel has changed
			if [[ $info[top] = $prompt_simpl_vcs_info[top] ]]; then
				# if stored pwd is part of $PWD, $PWD is shorter and likelier
				# to be toplevel, so we update pwd
				if [[ $prompt_simpl_vcs_info[pwd] =~ ^$PWD ]]; then
					prompt_simpl_vcs_info[pwd]=$PWD
				fi
			else
				# store $PWD to detect if we (maybe) left the git path
				prompt_simpl_vcs_info[pwd]=$PWD
			fi
			unset MATCH MBEGIN MEND

			# update has a git toplevel set which means we just entered a new
			# git directory, run the async refresh tasks
			[[ -n $info[top] ]] && [[ -z $prompt_simpl_vcs_info[top] ]] && prompt_simpl_async_refresh

			# always update branch and toplevel
			prompt_simpl_vcs_info[branch]=$info[branch]
			prompt_simpl_vcs_info[top]=$info[top]

			do_render=1
			;;
		prompt_simpl_async_git_aliases)
			if [[ -n $output ]]; then
				# append custom git aliases to the predefined ones.
				prompt_simpl_git_fetch_pattern+="|$output"
			fi
			;;
		prompt_simpl_async_git_dirty)
			local prev_dirty=$prompt_simpl_git_dirty
			if (( code == 0 )); then
				prompt_simpl_git_dirty=
			else
				prompt_simpl_git_dirty="${SIMPL_GIT_DIRTY_SYMBOL}"
			fi

			[[ $prev_dirty != $prompt_simpl_git_dirty ]] && do_render=1

			# When prompt_simpl_git_last_dirty_check_timestamp is set, the git info is displayed in a different color.
			# To distinguish between a "fresh" and a "cached" result, the preprompt is rendered before setting this
			# variable. Thus, only upon next rendering of the preprompt will the result appear in a different color.
			(( $exec_time > 5 )) && prompt_simpl_git_last_dirty_check_timestamp=$EPOCHSECONDS
			;;
		prompt_simpl_async_git_fetch|prompt_simpl_async_git_arrows)
			# prompt_simpl_async_git_fetch executes prompt_simpl_async_git_arrows
			# after a successful fetch.
			case $code in
				0)
					local REPLY
					prompt_simpl_check_git_arrows ${(ps:\t:)output}
					if [[ $prompt_simpl_git_arrows != $REPLY ]]; then
						typeset -g prompt_simpl_git_arrows=$REPLY
						do_render=1
					fi
					;;
				99|98)
					# Git fetch failed.
					;;
				*)
					# Non-zero exit status from prompt_simpl_async_git_arrows,
					# indicating that there is no upstream configured.
					if [[ -n $prompt_simpl_git_arrows ]]; then
						unset prompt_simpl_git_arrows
						do_render=1
					fi
					;;
			esac
			;;
	esac

	if (( next_pending )); then
		(( do_render )) && typeset -g prompt_simpl_async_render_requested=1
		return
	fi

	[[ ${prompt_simpl_async_render_requested:-$do_render} = 1 ]] && prompt_simpl_preprompt_render
	unset prompt_simpl_async_render_requested
}

prompt_simpl_state_setup() {
	setopt localoptions noshwordsplit

	# Check SSH_CONNECTION and the current state.
	local ssh_connection=${SSH_CONNECTION:-$PROMPT_SIMPL_SSH_CONNECTION}
	if [[ -z $ssh_connection ]] && (( $+commands[who] )); then
		# When changing user on a remote system, the $SSH_CONNECTION
		# environment variable can be lost, attempt detection via who.
		local who_out
		who_out=$(who -m 2>/dev/null)
		if (( $? )); then
			# Who am I not supported, fallback to plain who.
			local -a who_in
			who_in=( ${(f)"$(who 2>/dev/null)"} )
			who_out="${(M)who_in:#*[[:space:]]${TTY#/dev/}[[:space:]]*}"
		fi

		local reIPv6='(([0-9a-fA-F]+:)|:){2,}[0-9a-fA-F]+'  # Simplified, only checks partial pattern.
		local reIPv4='([0-9]{1,3}\.){3}[0-9]+'   # Simplified, allows invalid ranges.
		# Here we assume two non-consecutive periods represents a
		# hostname. This matches foo.bar.baz, but not foo.bar.
		local reHostname='([.][^. ]+){2}'

		# Usually the remote address is surrounded by parenthesis, but
		# not on all systems (e.g. busybox).
		local -H MATCH MBEGIN MEND
		if [[ $who_out =~ "\(?($reIPv4|$reIPv6|$reHostname)\)?\$" ]]; then
			ssh_connection=$MATCH

			# Export variable to allow detection propagation inside
			# shells spawned by this one (e.g. tmux does not always
			# inherit the same tty, which breaks detection).
			export PROMPT_SIMPL_SSH_CONNECTION=$ssh_connection
		fi
		unset MATCH MBEGIN MEND
	fi

	local username

	local at="${SIMPL_USER_HOST_PREPOSITION}${cl}"
	local in="${SIMPL_PREPOSITION_COLOR}in${cl}"

	local prompt="%(#.${SIMPL_PROMPT_ROOT_SYMBOL}.${SIMPL_PROMPT_SYMBOL})${cl}"
	local user="%(#.${SIMPL_USER_ROOT_COLOR}%n.${SIMPL_USER_COLOR}%n)${cl}"
	local host_symbol="$PROMPT_SIMPL_HOSTNAME_SYMBOL_MAP[$( hostname -s )]"

	# always show hostname symbol if available
	if [[ -n $host_symbol ]]; then
		username="${SIMPL_HOST_SYMBOL_COLOR}${host_symbol}${cl}"
		[[ "$SSH_CONNECTION" != '' || $UID -eq 0 ]] && username+=" ${user} ${in}"
	# only show username & hostname if connected via ssh
	elif [[ "$SSH_CONNECTION" != '' || $UID -eq 0 ]]; then
		[[ "$SSH_CONNECTION" != '' ]] && user+="${at}${SIMPL_HOST_COLOR}%m${cl}"
		username="${user} ${in}"
	fi

	typeset -gA prompt_simpl_state
	prompt_simpl_state=(
		username "${username}"
		prompt	 "${prompt}"
	)
}

prompt_simpl_setup() {
	# Prevent percentage showing up if output doesn't end with a newline.
	export PROMPT_EOL_MARK=''

	prompt_opts=(subst percent)

	# borrowed from promptinit, sets the prompt options in case simpl was not
	# initialized via promptinit.
	setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"

	setopt transientrprompt # only have the rprompt on the last line

	if [[ -z $prompt_newline ]]; then
		# This variable needs to be set, usually set by promptinit.
		typeset -g prompt_newline=$'\n%{\r%}'
	fi

	zmodload zsh/datetime
	zmodload zsh/zle
	zmodload zsh/parameter

	autoload -Uz add-zsh-hook
	autoload -Uz vcs_info
	autoload -Uz async && async

	# The add-zle-hook-widget function is not guaranteed
	# to be available, it was added in Zsh 5.3.
	autoload -Uz +X add-zle-hook-widget 2>/dev/null

	add-zsh-hook precmd prompt_simpl_precmd
	add-zsh-hook preexec prompt_simpl_preexec

	prompt_simpl_state_setup

	# prompt turns red if the previous command didn't exit with 0
	PROMPT="%(?.${SIMPL_PROMPT_SYMBOL_COLOR}.${SIMPL_PROMPT_SYMBOL_ERROR_COLOR})${prompt_simpl_state[prompt]}${cl} "

	PROMPT2="${SIMPL_PROMPT2_SYMBOL_COLOR}${prompt_simpl_state[prompt]}${cl} "

	# Store prompt expansion symbols for in-place expansion via (%). For
	# some reason it does not work without storing them in a variable first.
	typeset -ga prompt_simpl_debug_depth
	prompt_simmpl_debug_depth=('%e' '%N' '%x')

	# Compare is used to check if %N equals %x. When they differ, the main
	# prompt is used to allow displaying both file name and function. When
	# they match, we use the secondary prompt to avoid displaying duplicate
	# information.
	local -A ps4_parts
	ps4_parts=(
		depth 	  '%F{yellow}${(l:${(%)prompt_simpl_debug_depth[1]}::+:)}%f'
		compare   '${${(%)prompt_simpl_debug_depth[2]}:#${(%)prompt_simpl_debug_depth[3]}}'
		main      '%F{blue}${${(%)prompt_simpl_debug_depth[3]}:t}%f%F{242}:%I%f %F{242}@%f%F{blue}%N%f%F{242}:%i%f'
		secondary '%F{blue}%N%f%F{242}:%i'
		prompt 	  '%F{242}>%f '
	)
	# Combine the parts with conditional logic. First the `:+` operator is
	# used to replace `compare` either with `main` or an ampty string. Then
	# the `:-` operator is used so that if `compare` becomes an empty
	# string, it is replaced with `secondary`.
	local ps4_symbols='${${'${ps4_parts[compare]}':+"'${ps4_parts[main]}'"}:-"'${ps4_parts[secondary]}'"}'

	# Improve the debug prompt (PS4), show depth by repeating the +-sign and
	# add colors to highlight essential parts like file and function name.
	PROMPT4="${ps4_parts[depth]} ${ps4_symbols}${ps4_parts[prompt]}"

	unset ZSH_THEME  # Guard against Oh My Zsh themes overriding Simpl.

	# display virtualenv when activated in right prompt
	RPROMPT="%F{8}%(12V.${SIMPL_VENV_COLOR}%12v${cl} .)"
}

prompt_simpl_setup "$@"
