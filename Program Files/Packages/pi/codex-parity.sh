#!/usr/bin/env bash
set -euo pipefail

repo_root=${1:-.}
pi_config="$repo_root/Users/mirin/AppData/Development/pi.nix"
pi_package="$repo_root/Program Files/Packages/pi/default.nix"

failures=()
pi_help=$(pi --help)
codex_help=$(codex exec --help)
contains() {
  local file=$1
  local text=$2
  rg -Fq "$text" "$file"
}
check_present() {
  contains "$1" "$2" || failures+=("missing: $2")
}
check_absent() {
  contains "$1" "$2" && failures+=("unexpected: $2") || true
}

check_present "$pi_config" 'defaultProvider = "openai-codex";'
check_present "$pi_config" 'defaultModel = "gpt-5.6-sol";'
check_present "$pi_config" 'pkgs.pi-openai-codex-compat'
check_present "$pi_config" 'pkgs.pi-codex-workflow'
check_present "$pi_config" 'models-manager/prompt.md'
check_absent "$pi_config" 'pkgs.pi-dcp'
check_absent "$pi_config" 'pkgs.pi-observational-memory'
check_absent "$pi_config" 'observational-memory = {'
check_present "$pi_package" 'pname = "pi-openai-codex-compat";'
[[ $pi_help == *'--provider <name>'* ]] || failures+=("Pi lacks provider selection")
[[ $pi_help == *'--model <pattern>'* ]] || failures+=("Pi lacks model selection")
[[ $pi_help == *'--print, -p'* ]] || failures+=("Pi lacks non-interactive execution")
[[ $codex_help == *'--model <MODEL>'* ]] || failures+=("Codex lacks model selection")
[[ $codex_help == *'--json'* ]] || failures+=("Codex lacks structured event output")

total_checks=14
status=pass
if ((${#failures[@]} > 0)); then
  status=fail
fi

if [[ ${2:-text} == json ]]; then
  printf '{"status":"%s","passed":%d,"total":%d,"failures":[' "$status" "$((total_checks - ${#failures[@]}))" "$total_checks"
  if ((${#failures[@]} > 0)); then
    printf '%s' "$(printf '"%s",' "${failures[@]}" | sed 's/,$//')"
  fi
  printf ']}'
  printf '\n'
else
  printf '# Pi/Codex Parity Report\n\n'
  printf 'Status: **%s** (%d/%d checks)\n\n' "$status" "$((total_checks - ${#failures[@]}))" "$total_checks"
  printf 'Compared declarative provider/model selection, prompt provenance, compatibility extensions, compaction ownership, and both CLIs non-interactive/model-selection surfaces.\n'
  for failure in "${failures[@]}"; do
    printf -- '- %s\n' "$failure"
  done
fi

(( ${#failures[@]} == 0 ))
