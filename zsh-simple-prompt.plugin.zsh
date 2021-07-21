autoload -Uz add-zsh-hook

NOTIFIER=$(command -v terminal-notifier)
CURRENT_CMD=""

_zsh_simple_prompt__time() {
  date +%s%S
}

_zsh_simple_prompt__signal_name() {
  local sigs
  sigs=$(
    cat <<EOF
01 SIGHUP
02 SIGINT
03 SIGQUIT
04 SIGILL
05 SIGTRAP
06 SIGABRT
07 SIGEMT
08 SIGFPE
09 SIGKILL
10 SIGBUS
11 SIGSEGV
12 SIGSYS
13 SIGPIPE
14 SIGALRM
15 SIGTERM
16 SIGURG
17 SIGSTOP
18 SIGTSTP
19 SIGCONT
20 SIGCHLD
21 SIGTTIN
22 SIGTTOU
23 SIGIO
24 SIGXCPU
25 SIGXFSZ
26 SIGVTALRM
27 SIGPROF
28 SIGWINCH
29 SIGINFO
30 SIGUSR1
31 SIGUSR2
EOF
  )
  local query
  query=$(printf %02d "${1}")
  echo "${sigs}" | grep "${query}" | awk '{print $2}'
}

_zsh_simple_prompt__exitcode2signal() {
  local code=$1
  if [[ $code -gt 128 && $code -le $((128 + 31)) ]]; then
    local sigid signame
    sigid=$((code - 128))
    signame=$(_zsh_simple_prompt__signal_name $sigid)
    echo "${signame}"
    return
  fi
}

_zsh_simple_prompt__start_timer() {
  local cmd
  cmd="$1"
  if [[ -n "$cmd" ]]; then
    timer=$(_zsh_simple_prompt__time)
  fi
}
add-zsh-hook preexec _zsh_simple_prompt__start_timer

_zsh_simple_prompt__register_command_name() {
  CURRENT_CMD="$1"
}
add-zsh-hook preexec _zsh_simple_prompt__register_command_name

_zsh_simple_prompt__configure_prompt() {
  local code=$?
  psvar=()

  local st sig
  st=""
  sig=$(_zsh_simple_prompt__exitcode2signal $code)
  if [[ -n "${sig}" ]]; then
    st="${sig}($((code - 128)))"
  elif [[ "${code}" -ne 0 ]]; then
    st="${code}"
  fi

  local elapsed now t
  elapsed=""
  if [[ -n "$timer" ]]; then
    now=$(_zsh_simple_prompt__time)
    t=$((now - timer))
    elapsed="$(_zsh_simple_prompt__human_readable_elapsed_time $t)"
    unset timer
  fi

  [[ -n "$st" && -n "${CURRENT_CMD}" ]] && psvar[1]="$st "
  [[ -n "$elapsed" ]] && psvar[2]="$elapsed "
  [[ -n "${psvar[*]}" ]] && psvar[10]=1

  if [[ ${t} -ge ${SPL_PROMPT_NOTIFY_TIME_MIN} && -n "${NOTIFIER}" ]]; then
    local result
    [[ ${code} -eq 0 ]] &&
      result="DONE 👍" ||
      result="FAILED ‼️"
    ${NOTIFIER} \
      -title "${result}" \
      -subtitle "${CURRENT_CMD}" \
      -message "${psvar[1]}${psvar[2]}"
  fi

  unset CURRENT_CMD
}
add-zsh-hook precmd _zsh_simple_prompt__configure_prompt

_zsh_simple_prompt__human_readable_elapsed_time() {
  local o=''
  local t=$(($1 / 100))
  local ms=$(cut -b 2- <<<$(($1 % 100 + 100))) # 1.11 → 11, 1.1 → 10, 1.01 → 01
  t=$(cut -d. -f 1 <<<$t)
  h=$(($t / 3600))
  ((h > 0)) && o="${h}h"
  t=$((t % 3600))
  m=$(($t / 60))
  ((m > 0)) && o="${o}${m}m"
  s=$((t % 60))
  ((h == 0)) && ((m == 0)) && s="${s}.${ms}"
  [[ "$(bc <<<"$s > 0")" -eq 1 ]] && o="${o}${s}s"
  echo "${o}"
}

SPL_PROMPT_CMD_TIME_MIN=${SPL_PROMPT_CMD_TIME_MIN:-50}
SPL_PROMPT_NOTIFY_TIME_MIN=${SPL_PROMPT_NOTIFY_TIME_MIN:-60000}
PROMPT="%10(v|⇢ |)%F{yellow}%1v%f%F{blue}%2v%f%10(v|"$'\n'"|)""%(?,%F{green},%F{red})%B$%b%f "
