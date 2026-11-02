#!/usr/bin/env bash
# X-Scanner: X-Templates 3.29.0 + helpers projects-template; giữ hai phần khi cập nhật.
# _lib.sh — hàm dùng chung cho hook của khung X-Templates. Nguồn (source) từ hook khác.
# Mọi hook: fail-open (lỗi của hook không được kẹt phiên), chỉ dùng bash + python3 (jq tùy chọn).

XT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Đường dẫn xt.py: dự án đích cài khung vào .xtemplates/, còn repo khung thì ở scripts/.
xt_py() {
  for p in "$XT_ROOT/.xtemplates/scripts/xt.py" "$XT_ROOT/scripts/xt.py"; do
    [ -f "$p" ] && { printf '%s' "$p"; return 0; }
  done
  return 1
}

# Chạy file Python của khung như module (`main()`), sys.path[0] = thư mục của file như khi chạy script (không lấy cwd).
# `-I` (cách ly): bỏ biến PYTHON*, user-site (`usercustomize.py`) và cwd — mã agent đặt ở đó không chạy trước guard
# (AUD-SEC-065). `-B`: Python không ghi bytecode (không đẻ `__pycache__` cạnh hook). KHÔNG cache bytecode: biên dịch từ
# nguồn mỗi lần — thư mục agent ghi được không thể tin (header pyc checked-hash tính được từ nguồn công khai, phần
# marshal không ai kiểm — AUD-SEC-074, review PR #182); đổi lại thêm ~80–100 ms mỗi lệnh Bash. Bộ nạp giống hệt
# `PY_LOADER` của guard.py (test so).
py_run() { # $1=đường dẫn .py (có main()) $2…=đối số
  python3 -I -B -c 'import sys
p = sys.argv[1]
d, _, f = p.rpartition("/")
sys.path.insert(0, d or ".")
code = compile(open(p, "rb").read(), p, "exec", dont_inherit=True)
m = type(sys)(f[:-3])
m.__file__ = p
sys.modules[m.__name__] = m
sys.argv = sys.argv[1:]
exec(code, m.__dict__)
sys.exit(m.main())
' "$@"
}

# Chạy guard.py một lần, đặt XG_DECISION XG_REASON XG_COMMIT XG_NO_VERIFY XG_COMMIT_DIR (định dạng `nul` của guard.py) — không
# sinh thêm tiến trình python để tách trường. Trả 1 khi guard.py không trả kết quả (lỗi cú pháp, bị kill, thiếu file).
# Gọi bằng `guard_fields <mode> <<<"$payload"` (không qua ống: ống chạy hàm trong subshell, mất biến).
# shellcheck disable=SC2034 # XG_* là kết quả cho hook đã source file này
guard_fields() { # $1=bash|edit|mcp
  local ok=""
  XG_DECISION="" XG_REASON="" XG_COMMIT="" XG_NO_VERIFY="" XG_COMMIT_DIR=""
  {
    IFS= read -r -d '' ok
    IFS= read -r -d '' XG_DECISION
    IFS= read -r -d '' XG_REASON
    IFS= read -r -d '' XG_COMMIT
    IFS= read -r -d '' XG_NO_VERIFY
    IFS= read -r -d '' XG_COMMIT_DIR
  } < <(CLAUDE_PROJECT_DIR="$XT_ROOT" py_run "$(dirname "$0")/guard.py" "$1" nul 2>/dev/null)
  [ "$ok" = ok ]
}

# Đọc một trường trong payload JSON (stdin của hook) bằng python3; rỗng nếu thiếu.
json_field() { # $1=payload $2=đường dẫn dạng a.b.c
  printf '%s' "$1" | python3 -I -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sys.argv[1].split("."):
    d = d.get(k) if isinstance(d, dict) else None
    if d is None:
        sys.exit(0)
sys.stdout.write(d if isinstance(d, str) else json.dumps(d, ensure_ascii=False))
' "$2" 2>/dev/null
}

# In JSON quyết định PreToolUse (deny|ask|allow) kèm lý do, rồi exit 0.
pretool_decision() { # $1=deny|ask $2=lý do
  python3 -I -c '
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
      "permissionDecision": sys.argv[1], "permissionDecisionReason": sys.argv[2]}}, ensure_ascii=False))
' "$1" "$2"
  exit 0
}

# Hỏi người CHỈ khi `XT_GUARD_POLICY=strict` (hành vi cũ); mặc định cho qua để phiên không dừng chờ (ADR-0018). Luôn exit 0.
ask_strict() { # $1=lý do
  [ "${XT_GUARD_POLICY:-}" = strict ] && pretool_decision ask "$1"
  exit 0
}

# Không kiểm được thứ phải kiểm (merge khi guard vắng/lỗi — ADR-0019, AUD-SEC-045): strict hỏi, mặc định CHẶN. Luôn exit 0.
fence_closed() { # $1=lý do
  [ "${XT_GUARD_POLICY:-}" = strict ] && pretool_decision ask "$1"
  pretool_decision deny "${1#Khung cần xác nhận: }"
}

# Cắt stdin tối đa $1 byte KHÔNG cắt giữa ký tự UTF-8 (head -c từng làm hỏng tiếng Việt — AUD-HAR-011).
utf8_head() {
  python3 -I -c 'import sys; sys.stdout.write(sys.stdin.buffer.read()[: int(sys.argv[1])].decode("utf-8", "ignore"))' "$1" 2>/dev/null
}

# In JSON additionalContext cho SessionStart/UserPromptSubmit.
context_output() { # $1=hookEventName $2=nội dung
  python3 -I -c '
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": sys.argv[1],
      "additionalContext": sys.argv[2]}}, ensure_ascii=False))
' "$1" "$2"
}

# ===== PHẦN 2 — projects-template (hook cũ của repo) ===============================================================
# _lib.sh — hàm dùng chung cho các hook PreToolUse soi lệnh Bash (block-dangerous-git.sh, pre-commit-gate.sh).
# CHỈ để `source "$(dirname "$0")/_lib.sh"`, không tự chạy, không nối vào settings*.json. Không `set` gì ở đây:
# hook gọi đã tự đặt shell option (cố ý KHÔNG -e — docs/CONVENTIONS.md §A).
#
# VÌ SAO TÁCH RA (O-2, 2026-10-08 — TRAPS.md "bản sao hook lệch nhau"): hai hook từng giữ HAI BẢN SAO bộ lọc
# "bỏ dữ liệu trước khi so khớp". Lần sửa heredoc 2026-09-14 chỉ vào block-dangerous-git, nên pre-commit-gate
# vẫn coi thân heredoc là lệnh: `python3 - <<PY … git commit … PY` chạy cổng oan, message heredoc nhắc
# `git add` bật chế độ tự-stage oan. Một bản duy nhất ở đây = sửa một chỗ, cả hai hook cùng nhận.
# Chốt chặn: `scripts/test-hooks-gate.sh` mục 8 (block-dangerous-git) + mục 16 (pre-commit-gate).

# In lệnh Bash sắp chạy (`.tool_input.command`) từ payload JSON trên stdin; rỗng nếu không có.
# Hook gọi PHẢI tự kiểm `command -v jq` trước (mỗi hook giữ thông báo fail-open-có-cảnh-báo riêng).
read_hook_command() {
  jq -r '.tool_input.command // empty' 2>/dev/null
}

# Bỏ DỮ LIỆU trước khi so khớp, chỉ giữ phần thực sự là lệnh. Hai dạng nhúng dữ liệu nhiều từ vào
# một lệnh shell, và cả hai đều đã gây chặn oan thật:
#
#   1. Trong dấu nháy (audit 2026-09-12): `echo 'git reset --hard ...'` bị coi là lệnh git thật.
#   2. Trong thân heredoc (2026-09-14): `git commit -F - <<EOF ... EOF && git push -u origin
#      claude/<nhánh> --force-with-lease` bị quy tắc 1 chặn vì COMMIT MESSAGE có chữ "main" đứng
#      riêng ("quay về main"), dù nhánh đích là nhánh riêng. Cùng lượt đó quy tắc 2 cũng chặn oan
#      một lệnh `python3 - <<PY` mà thân script có chuỗi `git reset --hard` làm dữ liệu test.
#
# Đây là khuôn "bộ đếm/bộ dò tự khớp văn bản của chính thứ nó đang soi"
# (`docs/framework/quality-supplements-group2.md` §"Sổ trần cho LỐI THOÁT khỏi cổng coverage").
# Nguy hiểm của chặn oan không phải là phiền: nó dạy người ta gõ ALLOW_DANGEROUS_GIT=1 thành phản
# xạ, và lúc đó hàng rào không còn chặn được ca thật.
#
# CẨN TRỌNG khi sửa hàm dưới: bỏ NHẦM một dòng LÀ LỆNH thì hàng rào để lọt — hỏng theo chiều nguy
# hiểm, không phải chiều phiền. Bản đầu của chính lần sửa này dùng `<<-?[[:space:]]*DELIM`, và
# `echo "a << b"` khớp thành heredoc với delimiter `b` → mọi dòng SAU đó bị nuốt, nên
# `git reset --hard` ở dòng kế KHÔNG bị chặn (đo được, không phải suy đoán). Vì thế: KHÔNG cho phép
# khoảng trắng giữa `<<` và delimiter. Ca đó nay là một ca chặn bắt buộc ở `test-hooks-gate.sh` mục 7.
#
# GIỚI HẠN CÒN LẠI (nói ra, không giấu):
#   - dữ liệu KHÔNG nháy và KHÔNG heredoc vẫn bị quét — `git push -f origin claude/x && echo main`
#     vẫn chặn oan. Sửa hẳn cần tách lệnh theo `&&`/`;`/`|` rồi chỉ soi segment bắt đầu bằng `git`;
#     chưa làm vì phạm vi rộng hơn hẳn và chưa có sự cố thật.
#   - `cat << EOF` (có khoảng trắng — POSIX cho phép) không được nhận là heredoc nữa, nên thân nó
#     vẫn bị quét → có thể chặn oan. Đây là đánh đổi CỐ Ý: chặn oan thì người dùng thấy ngay và nói,
#     còn để lọt thì không ai biết. Chọn chiều an toàn.
#   - vỏ bọc chạy chuỗi (`bash -c`, `eval`) chỉ nhận dạng khi chuỗi đứng ngay sau (có thể qua cờ `-c`/`-lc`);
#     `cmd=…; eval "$cmd"` hay script ghi ra file rồi chạy thì hook KHÔNG thấy lệnh thật — hook là lưới đỡ
#     cho lỗi vô ý, không phải hàng rào chống người cố né (ruleset trên GitHub mới là hàng rào cứng).
# \047 = nháy đơn, \042 = nháy kép (escape bát phân của awk). Dùng chúng thay vì viết nháy thật để
# CẢ chương trình awk nằm gọn trong một cặp nháy đơn của shell — không có chỗ nào phải thoát nháy
# lồng nhau, thứ vừa khó đọc vừa dễ hỏng lặng lẽ khi ai đó sửa.
#
# Audit 2026-10-09 (TRAPS.md mục 62) vá thêm hai chỗ bỏ NHẦM dòng lệnh:
#   - `<<-EOF`: bash bỏ TAB đầu dòng trước khi so terminator → so `$0` sau khi bỏ tab; bản cũ so nguyên dòng nên
#     terminator thụt tab không bao giờ khớp và MỌI dòng sau (kể cả `git reset --hard`) bị nuốt.
#   - `<<` nằm TRONG chuỗi nháy (`echo "x <<EOF"`) không phải heredoc: chỉ nhận `<<` khi phần trước nó, sau khi bỏ
#     các cặp nháy đã đóng, không còn ký tự nháy lẻ (tức `<<` không ở trong chuỗi chưa đóng).
strip_heredoc_bodies() {
  awk '
    BEGIN { delim = ""; dash = 0 }
    {
      if (delim != "") {
        line = $0
        if (dash) sub(/^\t+/, "", line)
        if (line == delim) delim = ""
        next
      }
      rest = $0; pre = ""
      while (match(rest, /<<-?[\047\042]?[A-Za-z_][A-Za-z0-9_]*[\047\042]?/)) {
        before = pre substr(rest, 1, RSTART - 1)
        d = substr(rest, RSTART, RLENGTH)
        q = before
        gsub(/\047[^\047]*\047|\042[^\042]*\042/, "", q)
        if (q !~ /[\047\042]/) {
          dash = (d ~ /^<<-/)
          sub(/^<<-?/, "", d)
          gsub(/[\047\042]/, "", d)
          delim = d
          break
        }
        pre = before d
        rest = substr(rest, RSTART + RLENGTH)
      }
      print
    }'
}

# Bỏ phần TRONG DẤU NHÁY (đơn và kép) — dạng 1 ở trên. MỘT lượt trái→phải (một regex xen kẽ), không phải hai lượt
# nối tiếp: bản cũ bỏ nháy đơn trước nên `"don't" && git push --force origin main && echo "it's"` mất cả lệnh giữa
# (cặp `'…'` ghép từ hai chuỗi nháy kép khác nhau) — TRAPS.md mục 62.
strip_quoted() {
  sed -E "s/'[^']*'|\"[^\"]*\"//g"
}

# Chỉ bỏ KÝ TỰ nháy, giữ nội dung: dùng khi phần trong nháy có thể LÀ lệnh/tên nhánh (`-f origin "main"`,
# `bash -c 'git reset --hard'`). Rộng hơn strip_quoted → chỉ dùng ở chỗ chặn oan rẻ hơn để lọt.
strip_quote_marks() {
  tr -d "'\""
}

# Vỏ bọc chạy CHUỖI như lệnh: `bash -c '…'`, `sh -c "…"`, `zsh -lc '…'`, `eval "…"`.
HOOK_WRAPPER_RE="(^|[[:space:]])(bash|sh|zsh|eval)[[:space:]]+(-[A-Za-z]+[[:space:]]+)*[\"']"

# Văn bản để so khớp: bỏ thân heredoc, rồi bỏ phần trong nháy — TRỪ KHI lệnh có vỏ bọc chạy chuỗi, lúc đó phần trong
# nháy chính là lệnh nên chỉ bỏ ký tự nháy (chặn oan `echo "bash -c '…'"` là đánh đổi cố ý, chiều an toàn).
hook_scan_text() {   # $1 = lệnh gốc
  local body
  body="$(printf '%s' "$1" | strip_heredoc_bodies)"
  if printf '%s' "$body" | grep -Eq "$HOOK_WRAPPER_RE"; then
    printf '%s' "$body" | strip_quote_marks
  else
    printf '%s' "$body" | strip_quoted
  fi
}
