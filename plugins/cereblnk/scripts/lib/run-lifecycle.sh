# CB-169: avoid a YAML dependency by reading ACP's stable nested, dotted,
# and inline key shapes directly; acp-lint's parser is not reusable here.
_completion_rollup() {
  awk '
    function leading_spaces(s, t) {
      t = s
      sub(/[^ ].*$/, "", t)
      return length(t)
    }
    function token_value(s, t) {
      t = s
      sub(/^.*tokens_used[[:space:]]*:[[:space:]]*/, "", t)
      if (match(t, /^[0-9]+/)) return substr(t, RSTART, RLENGTH)
      return ""
    }
    function add_token(s, value) {
      value = token_value(s)
      if (value != "") {
        total += value
        found = 1
      }
    }
    FNR == 1 {
      if (NR > 1 && response) tasks++
      response = 0
      in_budget = 0
      budget_indent = -1
    }
    /^[[:space:]]*kind[[:space:]]*:[[:space:]]*response([[:space:]#]|$)/ {
      response = 1
    }
    /^[[:space:]]*budget_report[.]tokens_used[[:space:]]*:/ {
      add_token($0)
      next
    }
    /^[[:space:]]*budget_report[[:space:]]*:/ {
      if ($0 ~ /tokens_used[[:space:]]*:/) {
        add_token($0)
        in_budget = 0
      } else {
        in_budget = 1
        budget_indent = leading_spaces($0)
      }
      next
    }
    in_budget {
      if ($0 !~ /^[[:space:]]*(#.*)?$/ && leading_spaces($0) <= budget_indent) {
        in_budget = 0
      }
      if (in_budget && $0 ~ /^[[:space:]]*tokens_used[[:space:]]*:/) {
        add_token($0)
        in_budget = 0
      }
    }
    END {
      if (NR > 0 && response) tasks++
      printf "%d %d %d\n", found, total, tasks
    }
  ' "$@"
}

_completion_plan_metadata() {
  awk '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    BEGIN { workflow = "-"; risk = "-" }
    /^##/ { exit }
    /^-[[:space:]]*workflow[[:space:]]*:/ {
      line = $0
      sub(/^-[[:space:]]*workflow[[:space:]]*:[[:space:]]*/, "", line)
      line = trim(line)
      if (line != "") workflow = line
      next
    }
    /^-[[:space:]]*spec[[:space:]]*:/ {
      if (workflow == "-" && match($0, /\/cb-[A-Za-z0-9_-]+/))
        workflow = substr($0, RSTART, RLENGTH)
      next
    }
    /^-[[:space:]]*(request[[:space:]]+)?risk[[:space:]]*:/ {
      line = $0
      sub(/^-[[:space:]]*(request[[:space:]]+)?risk[[:space:]]*:[[:space:]]*/, "", line)
      gsub(/[*_]/, "", line)
      line = trim(line)
      split(line, parts, /[[:space:]]+/)
      value = tolower(parts[1])
      if (value == "med") value = "medium"
      if (value == "low" || value == "medium" || value == "high") risk = value
      next
    }
    END { printf "%s\t%s\n", workflow, risk }
  ' "$1"
}

_completion_plan_goal() {
  awk '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    /^##/ { exit }
    /^-[[:space:]]*goal[[:space:]]*:/ {
      line = $0
      sub(/^-[[:space:]]*goal[[:space:]]*:[[:space:]]*/, "", line)
      gsub(/[\t\r]/, " ", line)
      line = trim(line)
      if (line != "") print substr(line, 1, 120)
      exit
    }
  ' "$1"
}

# CB-172: prefer epoch<TAB>agent<TAB>path ledger entries; older runs fall
# back to artifacts/files-touched in Response Blocks.
_completion_review_paths() {
  _review_context="$1"
  _review_root="$2"
  if [ -f "$_review_context/edited-files.log" ]; then
    awk -F '\t' -v root="$_review_root/" '
      NF >= 3 {
        path = $3
        sub(/\r$/, "", path)
        if (index(path, root) == 1) path = substr(path, length(root) + 1)
        sub(/^\.\//, "", path)
        if (path != "") print path
      }
    ' "$_review_context/edited-files.log"
    unset _review_context _review_root
    return 0
  fi

  _review_yaml_files=("$_review_context"/*.yaml)
  if [ ! -e "${_review_yaml_files[0]}" ]; then
    unset _review_context _review_root _review_yaml_files
    return 0
  fi
  awk -v root="$_review_root/" '
    function leading_spaces(s, t) {
      t = s
      sub(/[^ ].*$/, "", t)
      return length(t)
    }
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    function add_path(value, quote) {
      value = trim(value)
      sub(/[[:space:]]+#.*$/, "", value)
      value = trim(value)
      quote = sprintf("%c", 39)
      if ((substr(value, 1, 1) == "\"" && substr(value, length(value), 1) == "\"") ||
          (substr(value, 1, 1) == quote && substr(value, length(value), 1) == quote))
        value = substr(value, 2, length(value) - 2)
      if (index(value, root) == 1) value = substr(value, length(root) + 1)
      sub(/^\.\//, "", value)
      if (value != "" && value != "[]") paths[++path_count] = value
    }
    function add_inline(value, count, values, i) {
      value = trim(value)
      sub(/^\[/, "", value)
      sub(/\][[:space:]]*$/, "", value)
      count = split(value, values, /,[[:space:]]*/)
      for (i = 1; i <= count; i++) add_path(values[i])
    }
    function flush_file(i) {
      if (response)
        for (i = 1; i <= path_count; i++) print paths[i]
      delete paths
      path_count = 0
      response = 0
      in_files = 0
      files_indent = -1
    }
    FNR == 1 {
      if (NR > 1) flush_file()
    }
    /^[[:space:]]*kind[[:space:]]*:[[:space:]]*response([[:space:]#]|$)/ {
      response = 1
    }
    in_files {
      if ($0 ~ /^[[:space:]]*(#.*)?$/) next
      if (leading_spaces($0) > files_indent &&
          $0 ~ /^[[:space:]]*-[[:space:]]+/) {
        value = $0
        sub(/^[[:space:]]*-[[:space:]]+/, "", value)
        add_path(value)
        next
      }
      in_files = 0
    }
    /^[[:space:]]*(artifacts|files[[:space:]_-]*touched)[[:space:]]*:/ {
      files_indent = leading_spaces($0)
      value = $0
      sub(/^[[:space:]]*(artifacts|files[[:space:]_-]*touched)[[:space:]]*:[[:space:]]*/, "", value)
      if (trim(value) == "") in_files = 1
      else add_inline(value)
      next
    }
    END { flush_file() }
  ' "${_review_yaml_files[@]}"
  unset _review_context _review_root _review_yaml_files
}

_completion_review_path_filter() {
  awk '
    {
      path = $0
      lower = tolower(path)
      if (lower ~ /(^|\/)\.claude\// ||
          lower ~ /^context\// ||
          lower ~ /\/cereblnk\/context\//)
        next

      basename = lower
      sub(/^.*\//, "", basename)
      if (basename == "plan.md" ||
          basename ~ /-required\.yaml$/ ||
          basename ~ /\.state$/ ||
          basename ~ /^digest\./ ||
          basename == "contract-baseline.txt" ||
          basename == "run-guard.last-progress" ||
          basename == "archive-pointer.txt" ||
          basename ~ /^t-.*\.yaml$/ ||
          basename ~ /^gate-.*\.yaml$/ ||
          basename ~ /^v-.*\.yaml$/)
        next

      print path
    }
  '
}

_completion_review_file_list() {
  _completion_review_paths "$1" "$2" 2>/dev/null \
    | _completion_review_path_filter \
    | LC_ALL=C sort -u \
    | awk '
        {
          count++
          if (count <= 10) list = list (list == "" ? "" : ",") $0
        }
        END {
          if (list == "") list = "-"
          if (count > 10) list = list ",+" (count - 10) " more"
          print list
        }
      '
}

# CB-178: abandonment never rolls memory back; report durable edits through
# the same authoritative ledger/fallback parser used for review.
_memory_touch_list() {
  _memory_context="$1"
  _memory_root="$2"
  _completion_review_paths "$_memory_context" "$_memory_root" 2>/dev/null \
    | awk '
        {
          path = $0
          sub(/^\.claude\/cereblnk\//, "", path)
          if (path ~ /^memory\/(contracts|briefs|requirements)(\/|$)/)
            print path
        }
      ' \
    | LC_ALL=C sort -u
  unset _memory_context _memory_root
}

_archive_spec_name() {
  _archive_spec_context="$1"
  if [ -f "$_archive_spec_context/plan.md" ]; then
    awk '
      function trim(s) {
        sub(/^[[:space:]]+/, "", s)
        sub(/[[:space:]]+$/, "", s)
        return s
      }
      /^-[[:space:]]*spec[[:space:]]*:/ {
        line = $0
        sub(/^-[[:space:]]*spec[[:space:]]*:[[:space:]]*/, "", line)
        gsub(/[\t\r]/, " ", line)
        line = trim(line)
        if (line != "") print line
        exit
      }
    ' "$_archive_spec_context/plan.md" 2>/dev/null
  fi
  unset _archive_spec_context
}

_archive_session_id() {
  _archive_session="${CLAUDE_SESSION_ID:-}"
  if [ -z "$_archive_session" ] && [ -f "$DIR/state.md" ] && \
     grep -q "^run_id: $_completion_run_id\$" "$DIR/state.md" 2>/dev/null; then
    _archive_session="$(sed -n 's/^session_id:[[:space:]]*//p' "$DIR/state.md" 2>/dev/null | head -n 1)"
  fi
  if [ -z "$_archive_session" ]; then
    _archive_history_date="${_completion_run_id#R-}"
    _archive_history_date="${_archive_history_date%-*}"
    _archive_history_date="${_archive_history_date//-/}"
    _archive_history_files=()
    for _archive_history_file in "$DIR/history/${_archive_history_date}"-*-*-*.jsonl; do
      [ -f "$_archive_history_file" ] || continue
      _archive_history_files+=("$_archive_history_file")
    done
    if [ "${#_archive_history_files[@]}" -eq 1 ]; then
      _archive_history_name="${_archive_history_files[0]##*/}"
      _archive_history_name="${_archive_history_name%.jsonl}"
      _archive_session="${_archive_history_name##*-}"
    fi
  fi
  if [ -z "$_archive_session" ] && \
     [ -d "$DIR/context/$_completion_run_id" ]; then
    _archive_session="$(
      grep -RhsE '^[[:space:]]*(session_id|sessionId)[[:space:]]*:' \
        "$DIR/context/$_completion_run_id" 2>/dev/null \
        | sed -E 's/^[[:space:]]*(session_id|sessionId)[[:space:]]*:[[:space:]]*//' \
        | head -n 1
    )"
  fi
  _archive_session="${_archive_session//$'\n'/ }"
  _archive_session="${_archive_session//$'\r'/ }"
  [ -n "$_archive_session" ] || _archive_session="-"
  printf '%s\n' "$_archive_session"
  unset _archive_session _archive_history_date _archive_history_files
  unset _archive_history_file _archive_history_name
}

_clear_run_transients() {
  _transient_context="$1"
  rm -f "$_transient_context/contract-baseline.txt" \
        "$_transient_context/run-guard.last-progress" 2>/dev/null || true
  for _transient_path in "$_transient_context"/*.state; do
    [ -e "$_transient_path" ] || continue
    rm -f "$_transient_path" 2>/dev/null || true
  done
  if [ -f "$_transient_context/contract-baseline.txt" ] || \
     [ -f "$_transient_context/run-guard.last-progress" ]; then
    echo "run-flag: could not clear transient state in $_transient_context." >&2
    unset _transient_context _transient_path
    return 1
  fi
  for _transient_path in "$_transient_context"/*.state; do
    if [ -e "$_transient_path" ]; then
      echo "run-flag: could not clear transient marker $_transient_path." >&2
      unset _transient_context _transient_path
      return 1
    fi
  done
  unset _transient_context _transient_path
  return 0
}

_mark_state_archived() {
  [ -f "$DIR/state.md" ] || return 0
  grep -q "^run_id: $_completion_run_id\$" "$DIR/state.md" 2>/dev/null || return 0
  _state_tmp="$DIR/state.md.$$"
  if sed \
      -e 's/^stage: .*/stage: archived/' \
      -e "s|^plan: context/$_completion_run_id/|plan: archive/$_completion_run_id/|" \
      "$DIR/state.md" > "$_state_tmp" 2>/dev/null; then
    mv -f "$_state_tmp" "$DIR/state.md" 2>/dev/null || rm -f "$_state_tmp" 2>/dev/null
  else
    rm -f "$_state_tmp" 2>/dev/null || true
  fi
  unset _state_tmp
}

_archive_preflight() {
  _archive_preflight_source="$DIR/context/$_completion_run_id"
  [ -d "$_archive_preflight_source" ] || {
    unset _archive_preflight_source
    return 0
  }
  _archive_preflight_parent="$DIR/archive"
  _archive_preflight_target="$_archive_preflight_parent/$_completion_run_id"
  if [ -e "$_archive_preflight_target" ]; then
    echo "run-flag: refusing to archive $_completion_run_id — $_archive_preflight_target already exists." >&2
    unset _archive_preflight_source _archive_preflight_parent _archive_preflight_target
    return 1
  fi
  if ! mkdir -p "$_archive_preflight_parent" 2>/dev/null || \
     [ ! -d "$_archive_preflight_parent" ]; then
    echo "run-flag: could not create $_archive_preflight_parent — the run remains live." >&2
    unset _archive_preflight_source _archive_preflight_parent _archive_preflight_target
    return 1
  fi
  unset _archive_preflight_source _archive_preflight_parent _archive_preflight_target
  return 0
}

_archive_run_context() {
  _archive_source="$DIR/context/$_completion_run_id"
  _archive_parent="$DIR/archive"
  _archive_target="$_archive_parent/$_completion_run_id"

  if [ ! -d "$_archive_source" ]; then
    echo "run-flag: no live context to archive for $_completion_run_id." >&2
    unset _archive_source _archive_parent _archive_target
    return 0
  fi
  if [ -e "$_archive_target" ]; then
    echo "run-flag: refusing to archive $_completion_run_id — $_archive_target already exists." >&2
    unset _archive_source _archive_parent _archive_target
    return 1
  fi
  if ! mkdir -p "$_archive_parent" 2>/dev/null || [ ! -d "$_archive_parent" ]; then
    echo "run-flag: could not create $_archive_parent — the run remains live." >&2
    unset _archive_source _archive_parent _archive_target
    return 1
  fi

  _archive_spec="$(_archive_spec_name "$_archive_source")"
  _archive_spec="${_archive_spec//$'\n'/ }"
  _archive_spec="${_archive_spec//$'\r'/ }"
  [ -n "$_archive_spec" ] || _archive_spec="-"
  _archive_session="$(_archive_session_id)"
  _archive_date="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf '%s\n' -)"
  [ -n "$_archive_date" ] || _archive_date="-"
  _archive_pointer="$_archive_source/archive-pointer.txt"
  _archive_pointer_tmp="$_archive_pointer.$$"
  if ! {
    printf 'run_id: %s\n' "$_completion_run_id"
    printf 'session_id: %s\n' "$_archive_session"
    printf 'spec: %s\n' "$_archive_spec"
    printf 'archived_at: %s\n' "$_archive_date"
  } > "$_archive_pointer_tmp" 2>/dev/null || \
     ! mv -f "$_archive_pointer_tmp" "$_archive_pointer" 2>/dev/null; then
    rm -f "$_archive_pointer_tmp" 2>/dev/null || true
    echo "run-flag: could not write $_archive_pointer — the run remains live." >&2
    unset _archive_source _archive_parent _archive_target _archive_spec
    unset _archive_session _archive_date _archive_pointer _archive_pointer_tmp
    return 1
  fi

  if ! mv "$_archive_source" "$_archive_target" 2>/dev/null; then
    echo "run-flag: could not move $_archive_source to $_archive_target." >&2
    unset _archive_source _archive_parent _archive_target _archive_spec
    unset _archive_session _archive_date _archive_pointer _archive_pointer_tmp
    return 1
  fi
  if [ ! -d "$_archive_target" ] || [ -e "$_archive_source" ]; then
    echo "run-flag: archive verification failed for $_completion_run_id." >&2
    unset _archive_source _archive_parent _archive_target _archive_spec
    unset _archive_session _archive_date _archive_pointer _archive_pointer_tmp
    return 1
  fi
  _mark_state_archived
  echo "run-flag: archived ($_archive_target)"
  unset _archive_source _archive_parent _archive_target _archive_spec
  unset _archive_session _archive_date _archive_pointer _archive_pointer_tmp
  return 0
}

_append_completion_telemetry() {
  _telemetry_run_id="$_completion_run_id"

  _workflow="-"
  _risk="-"
  _context_available=0
  _tokens_found=0
  _tokens_total=0
  _tasks_shipped=0
  _edited_files_nonempty=0
  _review_root=""
  _review_files="-"
  if [ -n "$_telemetry_run_id" ] && [ -d "$DIR/context/$_telemetry_run_id" ]; then
    _context_available=1
    _run_context="$DIR/context/$_telemetry_run_id"
    _review_root="$(dirname "$(dirname "$DIR")")"
    _review_files="$(_completion_review_file_list "$_run_context" "$_review_root" || printf '%s\n' -)"
    [ -n "$_review_files" ] || _review_files="-"
    if [ -s "$_run_context/edited-files.log" ] && [ "$_review_files" != "-" ]; then
      _edited_files_nonempty=1
    fi
    if [ -f "$_run_context/plan.md" ]; then
      IFS="$(printf '\t')" read -r _workflow _risk <<EOF
$(_completion_plan_metadata "$_run_context/plan.md" 2>/dev/null || printf '%s\t%s\n' - -)
EOF
      [ -n "$_workflow" ] || _workflow="-"
      [ -n "$_risk" ] || _risk="-"
    fi
    _yaml_files=("$_run_context"/*.yaml)
    if [ -e "${_yaml_files[0]}" ]; then
      read -r _tokens_found _tokens_total _tasks_shipped <<EOF
$(_completion_rollup "${_yaml_files[@]}" 2>/dev/null || printf '0 0 0\n')
EOF
    fi
  fi

  _line_run_id="${_telemetry_run_id:--}"
  _line_decision="${DECISION:--}"
  _line_gate="${GATE:--}"
  _line_decision="${_line_decision//$'\n'/ }"
  _line_decision="${_line_decision//$'\r'/ }"
  _line_gate="${_line_gate//$'\n'/ }"
  _line_gate="${_line_gate//$'\r'/ }"
  _telemetry_line="$_line_run_id · $_workflow · $_risk · $_line_gate · decision $_line_decision"
  if [ "$_tokens_found" -eq 1 ]; then
    _telemetry_line="$_telemetry_line · tokens_total=$_tokens_total"
  fi
  if [ "$_context_available" -eq 1 ]; then
    _telemetry_line="$_telemetry_line · tasks_shipped=$_tasks_shipped"
  fi

  mkdir -p "$DIR/telemetry" 2>/dev/null || true
  if ! printf '%s\n' "$_telemetry_line" >> "$DIR/telemetry/runs.log" 2>/dev/null; then
    echo "run-flag: could not append $DIR/telemetry/runs.log — completion telemetry was not recorded." >&2
  fi

  if [ "$_context_available" -eq 1 ] && \
     { [ "$_tasks_shipped" -gt 0 ] || [ "$_edited_files_nonempty" -eq 1 ]; }; then
    _review_summary=""
    if [ -f "$_run_context/plan.md" ]; then
      _review_summary="$(_completion_plan_goal "$_run_context/plan.md" 2>/dev/null || true)"
    fi
    [ -n "$_review_summary" ] || _review_summary="$DECISION"
    [ -n "$_review_summary" ] || _review_summary="-"
    _review_summary="${_review_summary//$'\n'/ }"
    _review_summary="${_review_summary//$'\r'/ }"
    _review_summary="${_review_summary//$'\t'/ }"
    _review_summary="${_review_summary:0:120}"
    _review_date="$(date -u +%Y-%m-%d 2>/dev/null || printf '%s\n' -)"
    [ -n "$_review_date" ] || _review_date="-"
    _review_line="$_review_date · $_line_run_id · reviewed=no · files=$_review_files · $_review_summary"
    if ! printf '%s\n' "$_review_line" >> "$DIR/telemetry/review-ledger.log" 2>/dev/null; then
      echo "run-flag: could not append $DIR/telemetry/review-ledger.log — the review record was not recorded." >&2
    fi
  fi
  unset _telemetry_run_id _workflow _risk _context_available
  unset _tokens_found _tokens_total _tasks_shipped _edited_files_nonempty
  unset _run_context _yaml_files _review_summary _review_root _review_files
  unset _review_date _review_line
  unset _line_run_id _line_decision _line_gate _telemetry_line
  return 0
}
