#!/usr/bin/env bash

# mod of Brainy 
# by zhaowb@gmail.com

#############
## Parsers ##
#############

__args() {
   ifs_old="$IFS" && IFS="|" args=( $1 ) && IFS="$ifs_old"
}

# __make_prompt() {  # list each prompt function in args
# 	# example:
# 	# __make_prompt $___BRAINY_TOP_LEFT
# 	# __make_prompt python clock dir
# 	for seg in $*; do
# 		info="$(___brainy_prompt_"${seg}")"
# 		[ -n "${info}" ] && ____brainy_top_left_parse "${info}"
# 	done
# }

____brainy_top_left_parse() {  # color|info[|box_color|box_left|box_right]
	__args $1
	[ -n "${args[3]}" ] && _TOP_LEFT+="${args[2]}${args[3]}"
	_TOP_LEFT+="${args[0]}${args[1]}"
	[ -n "${args[4]}" ] && _TOP_LEFT+="${args[2]}${args[4]}"
	_TOP_LEFT+=" "
}

____brainy_top_right_parse() {
	__args $1
	_TOP_RIGHT+=" "
	[ -n "${args[3]}" ] && _TOP_RIGHT+="${args[2]}${args[3]}"
	_TOP_RIGHT+="${args[0]}${args[1]}"
	[ -n "${args[4]}" ] && _TOP_RIGHT+="${args[2]}${args[4]}"
	(( __TOP_RIGHT_LEN += ${#args[1]} + ${#args[3]} + ${#args[4]} + 1 ))
}

____brainy_bottom_parse() {
	__args $1
	[ ${#args[1]} -gt 0 ] && _BOTTOM+="${args[0]}${args[1]} "
}

____brainy_top() {
	_TOP_LEFT=""
	_TOP_RIGHT=""
	__TOP_RIGHT_LEN=0

	for seg in ${___BRAINY_TOP_LEFT}; do
		info="$(___brainy_prompt_"${seg}")"
		[ -n "${info}" ] && ____brainy_top_left_parse "${info}"
	done

	for seg in ${___BRAINY_TOP_RIGHT}; do
		info="$(___brainy_prompt_"${seg}")"
		[ -n "${info}" ] && ____brainy_top_right_parse "${info}"
	done

	if [ $__TOP_RIGHT_LEN -gt 0 ]; then
	       (( __TOP_RIGHT_LEN -= 1 ))
		___cursor_right="\033[500C"
		___cursor_adjust="\033[${__TOP_RIGHT_LEN}D"
		_TOP_LEFT+="${___cursor_right}${___cursor_adjust}"
	fi

	printf "${_TOP_LEFT}${_TOP_RIGHT}"
}

____brainy_bottom() {
	_BOTTOM=""
	for seg in $___BRAINY_BOTTOM; do
		info="$(___brainy_prompt_"${seg}")"
		[ -n "${info}" ] && ____brainy_bottom_parse "${info}"
	done
	printf "\n%s" "${_BOTTOM}"
}

##############
## Segments ##
##############

___brainy_prompt_user_r() {  # user_info in the right
	color=$bold_blue
	if [ "${THEME_SHOW_SUDO}" == "true" ]; then
		if [ $(sudo -n id -u 2>&1 | grep 0) ]; then
			color=$bold_red
		fi
	fi
	box="[|]"
	info="$USER@$HOSTNAME"
	if [ -n "${SSH_CLIENT}" ]; then
		printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_white}" "${box}"
	else
		printf "%s|%s" "${color}" "${info}"
	fi
}

___brainy_prompt_dir_r() {  # dir in the right
	color=$bold_yellow
	box="[|]"
	info="$PWD"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_white}" "${box}"
}

___brainy_prompt_git_repo() {  # show git repo name
	scm
	[ $SCM != $SCM_GIT ] && return
	color=$bold_red
	box="(|)"
	box_color=$bold_white
	info="$(basename `git rev-parse --show-toplevel`)"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${box_color}" "${box}"
}


___brainy_prompt_user_info() {
	color=$bold_blue
	if [ "${THEME_SHOW_SUDO}" == "true" ]; then
		if [ $(sudo -n id -u 2>&1 | grep 0) ]; then
			color=$bold_red
		fi
	fi
	box="[|]"
	info="\u@\H"
	if [ -n "${SSH_CLIENT}" ]; then
		printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_white}" "${box}"
	else
		printf "%s|%s" "${color}" "${info}"
	fi
}

___brainy_prompt_dir() {
	color=$bold_yellow
	box="[|]"
	info="\w"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_white}" "${box}"
}

___brainy_prompt_scm() {
	[ "${THEME_SHOW_SCM}" != "true" ] && return
	color=$bold_green
	box="$(scm_char) "
	info="$(scm_prompt_info)"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_white}" "${box}"
}

___brainy_prompt_python() {
	[ "${THEME_SHOW_PYTHON}" != "true" ] && return
	color=$bold_yellow
	box="[|]"
	info="$(python_version_prompt)"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_blue}" "${box}"
}

___brainy_prompt_ruby() {
	[ "${THEME_SHOW_RUBY}" != "true" ] && return
	color=$bold_white
	box="[|]"
	info="rb-$(ruby_version_prompt)"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_red}" "${box}"
}

___brainy_prompt_todo() {
	[ "${THEME_SHOW_TODO}" != "true" ] ||
	[ -z "$(which todo.sh)" ] && return
	color=$bold_white
	box="[|]"
	info="t:$(todo.sh ls | egrep "TODO: [0-9]+ of ([0-9]+)" | awk '{ print $4 }' )"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_green}" "${box}"
}

___brainy_prompt_clock() {
	[ "${THEME_SHOW_CLOCK}" != "true" ] && return
	color=$THEME_CLOCK_COLOR
	box="[|]"
	info="$(date +"${THEME_CLOCK_FORMAT}")"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_purple}" "${box}"
}

___brainy_prompt_battery() {
	[ ! -e $OSH/plugins/battery/battery.plugin.sh ] ||
	[ "${THEME_SHOW_BATTERY}" != "true" ] && return
	info=$(battery_percentage)
	color=$bold_green
	if [ "$info" -lt 50 ]; then
		color=$bold_yellow
	elif [ "$info" -lt 25 ]; then
		color=$bold_red
	fi
	box="[|]"
	ac_adapter_connected && info+="+"
	[ "$info" == "100+" ] && info="AC"
	printf "%s|%s|%s|%s" "${color}" "${info}" "${bold_white}" "${box}"
}

___brainy_prompt_exitcode() {
	[ "${THEME_SHOW_EXITCODE}" != "true" ] && return
	color=$bold_purple
	[ "$exitcode" -ne 0 ] && printf "%s|%s" "${color}" "${exitcode}"
}

___brainy_prompt_char() {
	color=$bold_white
	prompt_char="${__BRAINY_PROMPT_CHAR_PS1}"
	printf "%s|%s" "${color}" "${prompt_char}"
}

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
VIRTUALENV_THEME_PROMPT_SUFFIX='@'
___BRAINY_TOP_LEFT=${___BRAINY_TOP_LEFT:-"python git_repo scm"}
# 'dir' 'user_info' can only in left because \w \u \h are evaluated in bash
# 'dir_r' 'user_r' are for right, they are evaluated before set in PS1
___BRAINY_TOP_RIGHT=${___BRAINY_TOP_RIGHT:-"dir_r user_r ruby todo battery"}
___BRAINY_BOTTOM=${___BRAINY_BOTTOM:-"clock exitcode char"}

############
## Prompt ##
############

__brainy_ps1() {
	printf "%s%s%s" "$(____brainy_top)" "$(____brainy_bottom)" "${normal}"
}

__brainy_ps2() {
	color=$bold_white
	printf "%s%s%s" "${color}" "${__BRAINY_PROMPT_CHAR_PS2}  " "${normal}"
}

_brainy_prompt() {
    exitcode="$?"

    PS1="$(__brainy_ps1)"
    PS2="$(__brainy_ps2)"
}

safe_append_prompt_command _brainy_prompt
