#!/usr/bin/env bash

# mod of Brainy by zhaowb@gmail.com

#########
## cli ##
#########

__brainy_show() {
	typeset _seg=${1:-}
	shift
	export THEME_SHOW_${_seg}=true
}

__brainy_hide() {
	typeset _seg=${1:-}
	shift
	export THEME_SHOW_${_seg}=false
}

_brainy_completion() {
	local cur _action actions segments
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	_action="${COMP_WORDS[1]}"
	actions="show hide"
	segments="battery clock exitcode python ruby scm sudo todo"
	case "${_action}" in
		show)
			COMPREPLY=( $(compgen -W "${segments}" -- "${cur}") )
			return 0
			;;
		hide)
			COMPREPLY=( $(compgen -W "${segments}" -- "${cur}") )
			return 0
			;;
	esac

	COMPREPLY=( $(compgen -W "${actions}" -- "${cur}") )
	return 0
}

brainy() {
	typeset action=${1:-}
	shift
	typeset segs=${*:-}
	typeset func
	case $action in
		show)
			func=__brainy_show;;
		hide)
			func=__brainy_hide;;
	esac
	for seg in ${segs}; do
		seg=$(printf "%s" "${seg}" | tr '[:lower:]' '[:upper:]')
		$func "${seg}"
	done
}

complete -F _brainy_completion brainy

###############
## Variables ##
###############

export SCM_THEME_PROMPT_PREFIX=""
export SCM_THEME_PROMPT_SUFFIX=""

export RBENV_THEME_PROMPT_PREFIX=""
export RBENV_THEME_PROMPT_SUFFIX=""
export RBFU_THEME_PROMPT_PREFIX=""
export RBFU_THEME_PROMPT_SUFFIX=""
export RVM_THEME_PROMPT_PREFIX=""
export RVM_THEME_PROMPT_SUFFIX=""

export SCM_THEME_PROMPT_DIRTY=" ${bold_red}✗${normal}"
export SCM_THEME_PROMPT_CLEAN=" ${bold_green}✓${normal}"

THEME_SHOW_SUDO=${THEME_SHOW_SUDO:-"true"}
THEME_SHOW_SCM=${THEME_SHOW_SCM:-"true"}
THEME_SHOW_RUBY=${THEME_SHOW_RUBY:-"false"}
THEME_SHOW_PYTHON=${THEME_SHOW_PYTHON:-"true"}  # change default to true
THEME_SHOW_CLOCK=${THEME_SHOW_CLOCK:-"true"}
THEME_SHOW_TODO=${THEME_SHOW_TODO:-"false"}
THEME_SHOW_BATTERY=${THEME_SHOW_BATTERY:-"false"}
THEME_SHOW_EXITCODE=${THEME_SHOW_EXITCODE:-"true"}

THEME_CLOCK_COLOR=${THEME_CLOCK_COLOR:-"$bold_white"}
THEME_CLOCK_FORMAT=${THEME_CLOCK_FORMAT:-"%H:%M:%S"}

__BRAINY_PROMPT_CHAR_PS1=${THEME_PROMPT_CHAR_PS1:-">"}
__BRAINY_PROMPT_CHAR_PS2=${THEME_PROMPT_CHAR_PS2:-"\\"}

VIRTUALENV_THEME_PROMPT_PREFIX=''
VIRTUALENV_THEME_PROMPT_SUFFIX=''
___BRAINY_TOP_LEFT=${___BRAINY_TOP_LEFT:-"python git_repo scm"}
# 'dir' 'user_info' can only in left because \w \u \h are evaluated in bash
# 'dir_r' 'user_r' are for right, they are evaluated before set in PS1
___BRAINY_TOP_RIGHT=${___BRAINY_TOP_RIGHT:-"dir_r user_r ruby todo battery"}
___BRAINY_BOTTOM=${___BRAINY_BOTTOM:-"clock exitcode char"}

############
## Prompt ##
############

__wenbo_theme_main() {  # don't mess up global env
	exitcode="$?"

	local PROMPT PROMPT_LEN  # output of make__promp()
	local color info box_color box_left box_right  # output of __xxx__()

	## Segments

	# set common color and box
	__default__() { info="" color=$bold_blue box_left="[" box_right="]" box_color=$bold_white; }

	__git_repo__() {  # show git repo name
		__default__
		scm
		[ $SCM == $SCM_GIT ] && info="$(basename `git rev-parse --show-toplevel`)" color=$bold_red box_left="git["
	}

	__user_r__() {  # user_info in the right
		__default__
		info="$USER@$HOSTNAME"  # instead of \u@\H ; use $VAR to get fixed length data
		[ "${THEME_SHOW_SUDO}" == "true" ] && [ $(sudo -n id -u 2>&1 | grep 0) ] && color=$bold_red
		[ "${SSH_CLIENT}" ] && box_left="" box_right=""
	}

	__user_info__() {
		__default__
		info="\u@\H"
		[ "${THEME_SHOW_SUDO}" == "true" ] && [ $(sudo -n id -u 2>&1 | grep 0) ] && color=$bold_red
		[ "${SSH_CLIENT}" ] && box_left="" box_right=""
	}

	__dir_r__() { __default__ ; info="$PWD" color=$bold_yellow; }  # dir in the right
	__dir__() { __default__ ; info="\w" color=$bold_yellow; }

	__scm__() {
		__default__
		[ "${THEME_SHOW_SCM}" == "true" ] && info="$(scm_prompt_info)" color=$bold_green box_left="$(scm_char) " box_right=""
	}

	__python__() {
		__default__
		[ "${THEME_SHOW_PYTHON}" == "true" ] && info="$(virtualenv_prompt)" color=$background_blue$bold_white box_color=$bold_yellow box_left="venv["
	}

	__ruby__() {
		__default__
		[ "${THEME_SHOW_RUBY}" == "true" ] && info="rb-$(ruby_version_prompt)" color=$bold_white box_color=$bold_red
	}

	__todo__() {
		__default__
		[ "${THEME_SHOW_TODO}" != "true" ] || [ -z "$(which todo.sh)" ] && return
		info="t:$(todo.sh ls | egrep "TODO: [0-9]+ of ([0-9]+)" | awk '{ print $4 }' )"
		color=$bold_white box_color=$bold_green
	}

	__clock__() {
		__default__
		[ "${THEME_SHOW_CLOCK}" == "true" ] && info="$(date +"${THEME_CLOCK_FORMAT}")" color=$THEME_CLOCK_COLOR box_left="" box_right=""
	}

	__battery__() {
		__default__
		[ ! -e $OSH/plugins/battery/battery.plugin.sh ] ||
		[ "${THEME_SHOW_BATTERY}" != "true" ] && return
		info=$(battery_percentage)
		color=$bold_green
		if [ "$info" -lt 50 ]; then
			color=$bold_yellow
		elif [ "$info" -lt 25 ]; then
			color=$bold_red
		fi
		ac_adapter_connected && info+="+"
		[ "$info" == "100+" ] && info="AC"
	}

	__exitcode__() {
		__default__
		[ "${THEME_SHOW_EXITCODE}" != "true" ] && return
		color=$bold_purple
		[ "$exitcode" -ne 0 ] && info="${exitcode}" color=$background_red$bold_white box_left="" box_right=""
	}

	__char__() { __default__; info="$__BRAINY_PROMPT_CHAR_PS1" color=$bold_white box_left="" box_right=""; }

	make_prompt() {  # list each prompt function in args
		# example:
		# make_prompt $___BRAINY_TOP_LEFT
		# make_prompt python clock dir
		PROMPT=""
		PROMPT_LEN=0
		local seg
		for seg in $*; do
			# sec1=$(date +%s.%N)
			__"${seg}"__  # setup color, info, box_color, box_left, box_right
			# sec2=$(date +%s.%N)
			# used=$(bc <<< "(($sec2-$sec1)*1000)/1")  # milliseconds in int
echo "$(date +%s.%N) wenbo theme seg $seg used $used ms" >> /tmp/home_profile.log
			# [ $used -gt 100 ] && echo make_prompt $seg used $used ms
			if [ -n "$info" ] ; then
				[ $PROMPT_LEN -gt 0 ] && PROMPT+=" " && ((PROMPT_LEN+=1))
				[ -n "$box_left" ] && PROMPT+="$box_color$box_left" && (( PROMPT_LEN += ${#box_left} ))
				PROMPT+="$color$info$normal" && (( PROMPT_LEN += ${#info} ))
				[ -n "$box_right" ] && PROMPT+="$box_color$box_right" && (( PROMPT_LEN += ${#box_right} ))
			fi
		done
	}

	_top() {
		local LEFT="" RIGHT="" RIGHT_LEN=0

		make_prompt $___BRAINY_TOP_LEFT ; LEFT="$PROMPT "
		make_prompt $___BRAINY_TOP_RIGHT ; RIGHT=" $PROMPT" RIGHT_LEN=$PROMPT_LEN

		if [ $RIGHT_LEN -gt 0 ]; then
			local ___cursor_right="\033[500C" ___cursor_adjust="\033[${RIGHT_LEN}D"
			echo "$LEFT$___cursor_right$___cursor_adjust$RIGHT"
		else
			echo "$LEFT"
		fi
	}

	_bottom() { make_prompt $___BRAINY_BOTTOM ; echo "$PROMPT"; }

echo "$(date +%s.%N) wenbo theme starts" >> /tmp/home_profile.log
	PS1="${cyan}┌─$(_top)\n${cyan}└─$(_bottom)$normal"
	PS2="$bold_white$__BRAINY_PROMPT_CHAR_PS2${normal}"
	unset -f __default__ __git_repo__ __user_r__ __user_info__ __dir__ __dir_r__ __scm__ __python__ __ruby__ __todo__ __clock__ __battery__ __exitcode__ __char__ make_prompt  _top _bottom
echo "$(date +%s.%N) wenbo theme ends" >> /tmp/home_profile.log
}

safe_append_prompt_command __wenbo_theme_main
# unset -f __wenbo_theme_main

