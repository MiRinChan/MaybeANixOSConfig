#!/usr/bin/env bash
set -euo pipefail

repo_root=${1:-.}
pi_config="$repo_root/Users/mirin/AppData/Development/pi.nix"
pi_package="$repo_root/Program Files/Packages/pi/default.nix"

failures=()
checks=0
pi_help=$(pi --help 2>&1 || true)
codex_help=$(codex exec --help 2>&1 || true)
contains() {
  local file=$1
  local text=$2
  rg -Fq "$text" "$file"
}
check_present() {
  checks=$((checks + 1))
  contains "$1" "$2" || failures+=("missing: $2")
}
check_absent() {
  checks=$((checks + 1))
  contains "$1" "$2" && failures+=("unexpected: $2") || true
}

check_present "$pi_config" 'defaultProvider = "kylenqaq-openai";'
check_present "$pi_config" 'defaultModel = "gpt-5.6-sol";'
check_present "$pi_config" '"kylenqaq-openai"'
check_present "$pi_config" '"api": "openai-codex-responses"'
check_present "$pi_package" '@narumitw/pi-goal'
check_present "$pi_config" 'pkgs.pi-codemode-extension'
check_present "$pi_config" 'pkgs.pi-tool-search'
check_present "$pi_config" 'pkgs.wj-pi-subagents'
check_present "$pi_config" 'pkgs.pi-openai-codex-compat'
check_present "$pi_config" 'pkgs.pi-codex-workflow'
check_present "$pi_config" 'models-manager/prompt.md'
check_present "$pi_config" 'pkgs.pi-goal'
check_present "$pi_config" '"tool_search"'
check_present "$pi_config" '"update_plan"'
check_present "$pi_config" 'request_user_input'
check_present "$pi_config" '"exec_command"'
check_present "$pi_config" '"write_stdin"'
check_present "$pi_config" '"apply_patch"'
check_present "$pi_config" '"web.run"'
check_present "$pi_config" 'responsesLite = true;'
check_present "$pi_config" 'permission-auto-review'
check_present "$pi_config" 'workspace-write'
check_present "$pi_package" 'pname = "pi-openai-codex-compat";'
check_present "$pi_package" 'pname = "pi-goal";'
check_present "$pi_package" 'pname = "pi-codemode-extension";'
check_present "$pi_package" 'pname = "pi-tool-search";'
check_present "$pi_package" 'pname = "wj-pi-subagents";'
check_present "$pi_package" 'npmDepsHash = "sha256-tqVVgzL+vsv+KCbKsm5tGTPKOwDb/bpAWQ6qWb1nx90=";'
check_present "$pi_package" 'npmDepsHash = "sha256-QBGuMN6CwjBYLsCWvpy4EtxthckbNL5SNM7bBkFrfXE=";'
check_absent "$pi_config" 'pkgs.pi-subagents'
check_absent "$pi_config" 'pkgs.pi-dcp'
check_absent "$pi_config" 'pkgs.pi-observational-memory'
check_absent "$pi_config" 'observational-memory = {'
((checks += 5))
[[ $pi_help == *'--provider <name>'* ]] || failures+=("Pi lacks provider selection")
[[ $pi_help == *'--model <pattern>'* ]] || failures+=("Pi lacks model selection")
[[ $pi_help == *'--print, -p'* ]] || failures+=("Pi lacks non-interactive execution")
[[ $codex_help == *'--model <MODEL>'* ]] || failures+=("Codex lacks model selection")
[[ $codex_help == *'--json'* ]] || failures+=("Codex lacks structured event output")

total_checks=$checks
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
