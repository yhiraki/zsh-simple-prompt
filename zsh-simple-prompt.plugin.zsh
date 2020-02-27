autoload -Uz add-zsh-hook

NOTIFIER=$(command -v terminal-notifier)
CURRENT_CMD=""

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
    timer=$(($(date +%s%0N) / 1000000))
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
    now=$(($(date +%s%0N) / 1000000))
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
  local elapsed=$1
  local t=($(_zsh_simple_prompt__elapsed_time "$1"))

  if [[ $elapsed -lt ${SPL_PROMPT_CMD_TIME_MIN} ]]; then
    return
  fi

  if [[ $elapsed -lt 500 ]]; then
    echo "${t[5]}ms"
    return
  fi

  local s
  s=$(echo "${t[4]} + (${t[5]} / 1000.0)" | bc -l)

  if [[ $elapsed -lt $((10 * 1000)) ]]; then
    printf %.2f "${s}"
    echo 's'
    return
  fi

  if [[ $elapsed -lt $((60 * 1000)) ]]; then
    printf %.1f "${s}"
    echo 's'
    return
  fi

  if [[ $elapsed -lt $((60 * 60 * 1000)) ]]; then
    echo "${t[3]}m${t[4]}s"
    return
  fi

  echo "${t[2]}h${t[3]}m"
}

_zsh_simple_prompt__elapsed_time() {
  local ret elapsed=$1

  local msec=1
  local sec=$((msec * 1000))
  local min=$((sec * 60))
  local hour=$((min * 60))

  local ret=()
  ret+=(0)
  ret+=($((elapsed / hour)))
  ret+=($((elapsed / min % 60)))
  ret+=($((elapsed / sec % 60)))
  ret+=($((elapsed / msec % 1000)))

  # days hours mins secs msecs
  echo ${ret[@]}
}

SPL_PROMPT_CMD_TIME_MIN=50
SPL_PROMPT_NOTIFY_TIME_MIN=60000
PROMPT="%10(v|⇢ |)%F{yellow}%1v%f%F{blue}%2v%f%10(v|"$'\n'"|)""%(?,%F{green},%F{red})%B$%b%f "
