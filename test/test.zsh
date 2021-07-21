#!/usr/bin/env zsh
set -e

cd $(dirname $0)

source ../zsh-simple-prompt.plugin.zsh

test() {
  local test="$1"
  local expected="$2"
  local got=$(eval "${test}")
  if [[ ! "${expected}" = "${got}" ]]; then
    echo "'${test}' => '${got}' != '${expected}'"
    exit 1
  fi
}

test '_zsh_simple_prompt__signal_name 1' 'SIGHUP'
test '_zsh_simple_prompt__signal_name 10' 'SIGBUS'

test '_zsh_simple_prompt__exitcode2signal 128' ''
test '_zsh_simple_prompt__exitcode2signal 129' 'SIGHUP'
test '_zsh_simple_prompt__exitcode2signal 159' 'SIGUSR2'
test '_zsh_simple_prompt__exitcode2signal 160' ''
test '_zsh_simple_prompt__exitcode2signal 255' ''

test '_zsh_simple_prompt__human_readable_elapsed_time 499' '4.99s'
test '_zsh_simple_prompt__human_readable_elapsed_time 500' '5.00s'
test '_zsh_simple_prompt__human_readable_elapsed_time 501' '5.01s'
test '_zsh_simple_prompt__human_readable_elapsed_time 1000' '10.00s'
test '_zsh_simple_prompt__human_readable_elapsed_time 1230' '12.30s'
test '_zsh_simple_prompt__human_readable_elapsed_time 5990' '59.90s'
test '_zsh_simple_prompt__human_readable_elapsed_time 5999' '59.99s'
test '_zsh_simple_prompt__human_readable_elapsed_time 6000' '1m'
test '_zsh_simple_prompt__human_readable_elapsed_time 359999' '59m59s'
test '_zsh_simple_prompt__human_readable_elapsed_time 360000' '1h'
test '_zsh_simple_prompt__human_readable_elapsed_time 360001' '1h'
test '_zsh_simple_prompt__human_readable_elapsed_time 720000' '2h'

echo done
