# SRC:  https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
# check whether printf supports -v
__git_printf_supports_v=
printf -v __git_printf_supports_v -- '%s' yes >/dev/null 2>&1

# like __git_SOH=$'\001' etc but works also in shells without $'...'
eval "$(printf '
	__git_SOH="\001" __git_STX="\002" __git_ESC="\033"
	__git_LF="\n" __git_CRLF="\r\n"
')"

# stores the divergence from upstream in $p
# used by GIT_PS1_SHOWUPSTREAM
__git_ps1_show_upstream ()
{
	local key value
	local svn_remotes="" svn_url_pattern="" count n
	local upstream_type=git legacy="" verbose="" name=""
	local LF="$__git_LF"

	# get some config options from git-config
	local output="$(git config -z --get-regexp '^(svn-remote\..*\.url|bash\.showupstream)$' 2>/dev/null | tr '\0\n' '\n ')"
	while read -r key value; do
		case "$key" in
		bash.showupstream)
			GIT_PS1_SHOWUPSTREAM="$value"
			if [ -z "${GIT_PS1_SHOWUPSTREAM}" ]; then
				p=""
				return
			fi
			;;
		svn-remote.*.url)
			svn_remotes=${svn_remotes}${value}${LF}  # URI\nURI\n...
			svn_url_pattern="$svn_url_pattern\\|$value"
			upstream_type=svn+git # default upstream type is SVN if available, else git
			;;
		esac
	done <<-OUTPUT
		$output
	OUTPUT

	# parse configuration values
	local option
	for option in ${GIT_PS1_SHOWUPSTREAM-}; do
		case "$option" in
		git|svn) upstream_type="$option" ;;
		verbose) verbose=1 ;;
		legacy)  legacy=1  ;;
		name)    name=1 ;;
		esac
	done

	# Find our upstream type
	case "$upstream_type" in
	git)    upstream_type="@{upstream}" ;;
	svn*)
		# successful svn-upstream resolution:
		# - get the list of configured svn-remotes ($svn_remotes set above)
		# - get the last commit which seems from one of our svn-remotes
		# - confirm that it is from one of the svn-remotes
		# - use $GIT_SVN_ID if set, else "git-svn"

		# get upstream from "git-svn-id: UPSTRM@N HASH" in a commit message
		# (git-svn uses essentially the same procedure internally)
		local svn_upstream="$(
			git log --first-parent -1 \
				--grep="^git-svn-id: \(${svn_url_pattern#??}\)" 2>/dev/null
		)"

		if [ -n "$svn_upstream" ]; then
			# extract the URI, assuming --grep matched the last line
			svn_upstream=${svn_upstream##*$LF}  # last line
			svn_upstream=${svn_upstream#*: }    # UPSTRM@N HASH
			svn_upstream=${svn_upstream%@*}     # UPSTRM

			case ${LF}${svn_remotes} in
			*"${LF}${svn_upstream}${LF}"*)
				# grep indeed matched the last line - it's our remote
				# default branch name for checkouts with no layout:
				upstream_type=${GIT_SVN_ID:-git-svn}
				;;
			*)
				# the commit message includes one of our remotes, but
				# it's not at the last line. is $svn_upstream junk?
				upstream_type=${svn_upstream#/}
				;;
			esac
		elif [ "svn+git" = "$upstream_type" ]; then
			upstream_type="@{upstream}"
		fi
		;;
	esac

	# Find how many commits we are ahead/behind our upstream
	if [ -z "$legacy" ]; then
		count="$(git rev-list --count --left-right \
				"$upstream_type"...HEAD 2>/dev/null)"
	else
		# produce equivalent output to --count for older versions of git
		local commits
		if commits="$(git rev-list --left-right "$upstream_type"...HEAD 2>/dev/null)"
		then
			local commit behind=0 ahead=0
			for commit in $commits
			do
				case "$commit" in
				"<"*) behind=$((behind+1)) ;;
				*)    ahead=$((ahead+1))   ;;
				esac
			done
			count="$behind	$ahead"
		else
			count=""
		fi
	fi

	# calculate the result
	if [ -z "$verbose" ]; then
		case "$count" in
		"") # no upstream
			p="" ;;
		"0	0") # equal to upstream
			p="=" ;;
		"0	"*) # ahead of upstream
			p=">" ;;
		*"	0") # behind upstream
			p="<" ;;
		*)	    # diverged from upstream
			p="<>" ;;
		esac
	else # verbose, set upstream instead of p
		case "$count" in
		"") # no upstream
			upstream="" ;;
		"0	0") # equal to upstream
			upstream="|u=" ;;
		"0	"*) # ahead of upstream
			upstream="|u+${count#0	}" ;;
		*"	0") # behind upstream
			upstream="|u-${count%	0}" ;;
		*)	    # diverged from upstream
			upstream="|u+${count#*	}-${count%	*}" ;;
		esac
		if [ -n "$count" ] && [ -n "$name" ]; then
			__git_ps1_upstream_name=$(git rev-parse \
				--abbrev-ref "$upstream_type" 2>/dev/null)
			if [ "$pcmode" = yes ] && [ "$ps1_expanded" = yes ]; then
				upstream="$upstream \${__git_ps1_upstream_name}"
			else
				upstream="$upstream ${__git_ps1_upstream_name}"
				# not needed anymore; keep user's
				# environment clean
				unset __git_ps1_upstream_name
			fi
		fi
	fi

}

# Helper function that is meant to be called from __git_ps1.  It
# injects color codes into the appropriate gitstring variables used
# to build a gitstring. Colored variables are responsible for clearing
# their own color.
__git_ps1_colorize_gitstring ()
{
	if [ -n "${ZSH_VERSION-}" ]; then
		local c_red='%F{red}'
		local c_green='%F{green}'
		local c_lblue='%F{blue}'
		local c_clear='%f'
	else
		# \001 (SOH) and \002 (STX) are 0-width substring markers
		# which bash/readline identify while calculating the prompt
		# on-screen width - to exclude 0-screen-width esc sequences.
		local c_pre="${GIT_PS1_COLOR_PRE-$__git_SOH}${__git_ESC}["
		local c_post="m${GIT_PS1_COLOR_POST-$__git_STX}"

		local c_red="${c_pre}31${c_post}"
		local c_green="${c_pre}32${c_post}"
		local c_lblue="${c_pre}1;34${c_post}"
		local c_clear="${c_pre}0${c_post}"
	fi
	local bad_color="$c_red"
	local ok_color="$c_green"
	local flags_color="$c_lblue"

	local branch_color=""
	if [ "$detached" = no ]; then
		branch_color="$ok_color"
	else
		branch_color="$bad_color"
	fi
	if [ -n "$c" ]; then
		c="$branch_color$c$c_clear"
	fi
	b="$branch_color$b$c_clear"

	if [ -n "$w" ]; then
		w="$bad_color$w$c_clear"
	fi
	if [ -n "$i" ]; then
		i="$ok_color$i$c_clear"
	fi
	if [ -n "$s" ]; then
		s="$flags_color$s$c_clear"
	fi
	if [ -n "$u" ]; then
		u="$bad_color$u$c_clear"
	fi
}

# Helper function to read the first line of a file into a variable.
# __git_eread requires 2 arguments, the file path and the name of the
# variable, in that order.
__git_eread ()
{
	test -r "$1" && IFS=$__git_CRLF read -r "$2" <"$1"
}

# see if a cherry-pick or revert is in progress, if the user has committed a
# conflict resolution with 'git commit' in the middle of a sequence of picks or
# reverts then CHERRY_PICK_HEAD/REVERT_HEAD will not exist so we have to read
# the todo file.
__git_sequencer_status ()
{
	local todo
	if test -f "$g/CHERRY_PICK_HEAD"
	then
		r="|CHERRY-PICKING"
		return 0;
	elif test -f "$g/REVERT_HEAD"
	then
		r="|REVERTING"
		return 0;
	elif __git_eread "$g/sequencer/todo" todo
	then
		case "$todo" in
		p[\ \	]|pick[\ \	]*)
			r="|CHERRY-PICKING"
			return 0
		;;
		revert[\ \	]*)
			r="|REVERTING"
			return 0
		;;
		esac
	fi
	return 1
}

# __git_ps1 accepts 0 or 1 arguments (i.e., format string)
# when called from PS1 using command substitution
# in this mode it prints text to add to bash PS1 prompt (includes branch name)
#
# __git_ps1 requires 2 or 3 arguments when called from PROMPT_COMMAND (pc)
# in that case it _sets_ PS1. The arguments are parts of a PS1 string.
# when two arguments are given, the first is prepended and the second appended
# to the state string when assigned to PS1.
# The optional third parameter will be used as printf format string to further
# customize the output of the git-status string.
# In this mode you can request colored hints using GIT_PS1_SHOWCOLORHINTS=true
__git_ps1 ()
{
	# preserve exit status
	local exit="$?"
	local pcmode=no
	local detached=no
	local ps1pc_start='\u@\h:\w '
	local ps1pc_end='\$ '
	local printf_format=' (%s)'

	case "$#" in
		2|3)	pcmode=yes
			ps1pc_start="$1"
			ps1pc_end="$2"
			printf_format="${3:-$printf_format}"
			# set PS1 to a plain prompt so that we can
			# simply return early if the prompt should not
			# be decorated
			PS1="$ps1pc_start$ps1pc_end"
		;;
		0|1)	printf_format="${1:-$printf_format}"
		;;
		*)	return "$exit"
		;;
	esac

	# ps1_expanded:  This variable is set to 'yes' if the shell
	# subjects the value of PS1 to parameter expansion:
	#
	#   * bash does unless the promptvars option is disabled
	#   * zsh does not unless the PROMPT_SUBST option is set
	#   * POSIX shells always do
	#
	# If the shell would expand the contents of PS1 when drawing
	# the prompt, a raw ref name must not be included in PS1.
	# This protects the user from arbitrary code execution via
	# specially crafted ref names.  For example, a ref named
	# 'refs/heads/$(IFS=_;cmd=sudo_rm_-rf_/;$cmd)' might cause the
	# shell to execute 'sudo rm -rf /' when the prompt is drawn.
	#
	# Instead, the ref name should be placed in a separate global
	# variable (in the __git_ps1_* namespace to avoid colliding
	# with the user's environment) and that variable should be
	# referenced from PS1.  For example:
	#
	#     __git_ps1_foo=$(do_something_to_get_ref_name)
	#     PS1="...stuff...\${__git_ps1_foo}...stuff..."
	#
	# If the shell does not expand the contents of PS1, the raw
	# ref name must be included in PS1.
	#
	# The value of this variable is only relevant when in pcmode.
	#
	# Assume that the shell follows the POSIX specification and
	# expands PS1 unless determined otherwise.  (This is more
	# likely to be correct if the user has a non-bash, non-zsh
	# shell and safer than the alternative if the assumption is
	# incorrect.)
	#
	local ps1_expanded=yes
	[ -z "${ZSH_VERSION-}" ] || eval '[[ -o PROMPT_SUBST ]]' || ps1_expanded=no
	[ -z "${BASH_VERSION-}" ] || shopt -q promptvars || ps1_expanded=no

	local repo_info rev_parse_exit_code
	repo_info="$(git rev-parse --git-dir --is-inside-git-dir \
		--is-bare-repository --is-inside-work-tree --show-ref-format \
		--short HEAD 2>/dev/null)"
	rev_parse_exit_code="$?"

	if [ -z "$repo_info" ]; then
		return "$exit"
	fi

	local LF="$__git_LF"
	local short_sha=""
	if [ "$rev_parse_exit_code" = "0" ]; then
		short_sha="${repo_info##*$LF}"
		repo_info="${repo_info%$LF*}"
	fi
	local ref_format="${repo_info##*$LF}"
	repo_info="${repo_info%$LF*}"
	local inside_worktree="${repo_info##*$LF}"
	repo_info="${repo_info%$LF*}"
	local bare_repo="${repo_info##*$LF}"
	repo_info="${repo_info%$LF*}"
	local inside_gitdir="${repo_info##*$LF}"
	local g="${repo_info%$LF*}"

	if [ "true" = "$inside_worktree" ] &&
	   [ -n "${GIT_PS1_HIDE_IF_PWD_IGNORED-}" ] &&
	   [ "$(git config --bool bash.hideIfPwdIgnored)" != "false" ] &&
	   git check-ignore -q .
	then
		return "$exit"
	fi

	local sparse=""
	if [ -z "${GIT_PS1_COMPRESSSPARSESTATE-}" ] &&
	   [ -z "${GIT_PS1_OMITSPARSESTATE-}" ] &&
	   [ "$(git config --bool core.sparseCheckout)" = "true" ]; then
		sparse="|SPARSE"
	fi

	local r=""
	local b=""
	local step=""
	local total=""
	if [ -d "$g/rebase-merge" ]; then
		__git_eread "$g/rebase-merge/head-name" b
		__git_eread "$g/rebase-merge/msgnum" step
		__git_eread "$g/rebase-merge/end" total
		r="|REBASE"
	else
		if [ -d "$g/rebase-apply" ]; then
			__git_eread "$g/rebase-apply/next" step
			__git_eread "$g/rebase-apply/last" total
			if [ -f "$g/rebase-apply/rebasing" ]; then
				__git_eread "$g/rebase-apply/head-name" b
				r="|REBASE"
			elif [ -f "$g/rebase-apply/applying" ]; then
				r="|AM"
			else
				r="|AM/REBASE"
			fi
		elif [ -f "$g/MERGE_HEAD" ]; then
			r="|MERGING"
		elif __git_sequencer_status; then
			:
		elif [ -f "$g/BISECT_LOG" ]; then
			r="|BISECTING"
		fi

		if [ -n "$b" ]; then
			:
		elif [ -h "$g/HEAD" ]; then
			# symlink symbolic ref
			b="$(git symbolic-ref HEAD 2>/dev/null)"
		else
			local head=""

			case "$ref_format" in
			files)
				if ! __git_eread "$g/HEAD" head; then
					return "$exit"
				fi

				case $head in
				"ref: "*)
					head="${head#ref: }"
					;;
				*)
					head=""
				esac
				;;
			*)
				head="$(git symbolic-ref HEAD 2>/dev/null)"
				;;
			esac

			if test -z "$head"; then
				detached=yes
				b="$(
				case "${GIT_PS1_DESCRIBE_STYLE-}" in
				(contains)
					git describe --contains HEAD ;;
				(branch)
					git describe --contains --all HEAD ;;
				(tag)
					git describe --tags HEAD ;;
				(describe)
					git describe HEAD ;;
				(* | default)
					git describe --tags --exact-match HEAD ;;
				esac 2>/dev/null)" ||

				b="$short_sha..."
				b="($b)"
			else
				b="$head"
			fi
		fi
	fi

	if [ -n "$step" ] && [ -n "$total" ]; then
		r="$r $step/$total"
	fi

	local conflict="" # state indicator for unresolved conflicts
	if [ "${GIT_PS1_SHOWCONFLICTSTATE-}" = "yes" ] &&
	   [ "$(git ls-files --unmerged 2>/dev/null)" ]; then
		conflict="|CONFLICT"
	fi

	local w=""
	local i=""
	local s=""
	local u=""
	local h=""
	local c=""
	local p="" # short version of upstream state indicator
	local upstream="" # verbose version of upstream state indicator

	if [ "true" = "$inside_gitdir" ]; then
		if [ "true" = "$bare_repo" ]; then
			c="BARE:"
		else
			b="GIT_DIR!"
		fi
	elif [ "true" = "$inside_worktree" ]; then
		if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] &&
		   [ "$(git config --bool bash.showDirtyState)" != "false" ]
		then
			git diff --no-ext-diff --quiet || w="*"
			git diff --no-ext-diff --cached --quiet || i="+"
			if [ -z "$short_sha" ] && [ -z "$i" ]; then
				i="#"
			fi
		fi
		if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ] &&
		   git rev-parse --verify --quiet refs/stash >/dev/null
		then
			s="$"
		fi

		if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] &&
		   [ "$(git config --bool bash.showUntrackedFiles)" != "false" ] &&
		   git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' >/dev/null 2>/dev/null
		then
			u="%${ZSH_VERSION+%}"
		fi

		if [ -n "${GIT_PS1_COMPRESSSPARSESTATE-}" ] &&
		   [ "$(git config --bool core.sparseCheckout)" = "true" ]; then
			h="?"
		fi

		if [ -n "${GIT_PS1_SHOWUPSTREAM-}" ]; then
			__git_ps1_show_upstream
		fi
	fi

	local z="${GIT_PS1_STATESEPARATOR- }"

	b=${b##refs/heads/}
	if [ "$pcmode" = yes ] && [ "$ps1_expanded" = yes ]; then
		__git_ps1_branch_name=$b
		b="\${__git_ps1_branch_name}"
	fi

	if [ -n "${GIT_PS1_SHOWCOLORHINTS-}" ]; then
		__git_ps1_colorize_gitstring
	fi

	local f="$h$w$i$s$u$p"
	local gitstring="$c$b${f:+$z$f}${sparse}$r${upstream}${conflict}"

	if [ "$pcmode" = yes ]; then
		if [ "${__git_printf_supports_v-}" != yes ]; then
			gitstring=$(printf -- "$printf_format" "$gitstring")
		else
			printf -v gitstring -- "$printf_format" "$gitstring"
		fi
		PS1="$ps1pc_start$gitstring$ps1pc_end"
	else
		printf -- "$printf_format" "$gitstring"
	fi

	return "$exit"
}



PS1='\[\e[01;30m\]\t `if [ $? = 0 ]; then echo "\[\033[01;32m\]✔"; else echo "\[\033[01;31m\]✘"; fi`  \[\e[00;37m\]\u@\h\[\e[01;37m\]:`[[ $(git status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo "\[\e[31m\]" || echo "\[\e[32m\]"`$(__git_ps1 "(%s)\[\e[00m\]")\[\e[01;34m\]\w\[\e[00m\] > '
