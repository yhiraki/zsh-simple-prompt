#!/usr/bin/env zsh
set -e

cd $(dirname $0)

source ../zsh-simple-prompt.plugin.zsh

test() {
  local test="$1"
  local expected="$2"
  local got=$(eval "${test}")
  if [[ ! "${expected}" = "${got}"  ]]
  then
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

test '_zsh_simple_prompt__human_readable_elapsed_time 499' '499ms'
test '_zsh_simple_prompt__human_readable_elapsed_time 500' '0.50s'
test '_zsh_simple_prompt__human_readable_elapsed_time 501' '0.50s'
test '_zsh_simple_prompt__human_readable_elapsed_time 1000' '1.00s'
test '_zsh_simple_prompt__human_readable_elapsed_time 1230' '1.23s'
test '_zsh_simple_prompt__human_readable_elapsed_time 59900' '59.9s'
test '_zsh_simple_prompt__human_readable_elapsed_time 59999' '60.0s'
test '_zsh_simple_prompt__human_readable_elapsed_time 60000' '1m0s'
test '_zsh_simple_prompt__human_readable_elapsed_time 3599999' '59m59s'
test '_zsh_simple_prompt__human_readable_elapsed_time 3600000' '1h0m'
test '_zsh_simple_prompt__human_readable_elapsed_time 3600001' '1h0m'
test '_zsh_simple_prompt__human_readable_elapsed_time 7200000' '2h0m'

echo done
