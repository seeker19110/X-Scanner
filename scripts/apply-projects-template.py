#!/usr/bin/env python3
"""One-time adoption using the upstream copy script; does not implement the app."""
from __future__ import annotations
import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

PIN = 'aab9f887ec4acc4480da852cc300978979087f6b'
RESEARCH = 'docs/research/2026-10-11-scanner-product-suggestions.md'


def write(root: Path, name: str, content: str) -> None:
    dest = root / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content.rstrip() + '\n', encoding='utf-8')


def apply(source: Path, target: Path) -> None:
    actual = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != PIN:
        raise RuntimeError(f'Unexpected template commit: {actual}')
    if source == target or source in target.parents or target in source.parents:
        raise RuntimeError('Source and target must be separate checkouts')
    if (target / 'docs/framework/FRAMEWORK-VERSION').exists():
        raise RuntimeError('Already installed; review upstream --upgrade rather than rerun this importer')
    original = (target / RESEARCH).read_bytes()
    subprocess.run(['bash', str(source / 'copy-framework.sh'), str(target), '--no-hooks'], check=True)
    drop = target / '_framework-dropins'
    adopted = ('.gitignore', '.gitattributes', '.github/pull_request_template.md', '.github/ISSUE_TEMPLATE')
    for rel in adopted:
        src, dst = drop / rel, target / rel
        if not src.exists() or dst.exists():
            raise RuntimeError(f'Missing source or existing destination: {rel}')
        dst.parent.mkdir(parents=True, exist_ok=True)
        if src.is_dir():
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)
    archive = target / 'docs/adoption/deferred-dropins'
    for src in sorted(drop.rglob('*')):
        if src.is_file():
            dst = archive / (str(src.relative_to(drop)) + '.example')
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
    shutil.rmtree(drop)
    for rel in ('.nvmrc', '.codex/config.toml'):
        src = target / rel
        if src.exists():
            dst = archive / (rel + '.example')
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dst))
    write(target, '.codex/config.toml', '# Inherit local provider/model/context configuration; no credentials or paid automation selected.')
    settings = json.loads((target / '.claude/settings.json').read_text(encoding='utf-8'))
    for key in ('model', 'fallbackModel', 'effortLevel', 'env'):
        settings.pop(key, None)
    # Preserve upstream Context7 permission for developer documentation only.
    write(target, '.claude/settings.json', json.dumps(settings, ensure_ascii=False, indent=2))
    overlay = f'''# X-Scanner — project context (2026-10-11)

Read PROJECT.md, PROGRESS.md and `{RESEARCH}` first. Research is **ADVISORY**, not approved architecture.
Only saving suggestions and framework adoption is approved in this change. No app source exists yet.
Template example stacks/models and the proposed P0–P4 roadmap do not authorize product implementation.
Use `.claude/project-commands.sh`: `bash scripts/dev-task.sh doctor` and `bash scripts/dev-task.sh gate`.
Build/typecheck N/A applies only to this adoption; replace with real app checks before product implementation.
Framework PASS is not evidence of mobile build, scan, OCR, depth or release quality.
Inherit a live model from the operator's provider; no paid API is required. Context7 is for developer docs only; never send scans or OCR.
Parallel work requires disjoint files, separate worktrees and agreed interface contracts.
Never upload real documents/OCR, log sensitive contents, invent missing text or discard scan originals.
Do not activate release, auto-merge, schedulers, cloud services or X-Agents from this advisory alone.
Each developer checkout needs `git config core.hooksPath scripts/githooks`, Bash >=4 and jq.
Do not change global Git configuration. Repository-level branch protection is not yet verified.
This context governs X-Scanner over generic examples and unfilled product placeholders below.

---

'''
    for name in ('AGENTS.md', 'CLAUDE.md'):
        write(target, name, overlay + (target / name).read_text(encoding='utf-8'))
    files = {
        'README.md': f'''# X-Scanner

Ứng dụng scan tài liệu, hướng tới xuất **PDF hoặc ảnh**.
**Trạng thái: bộ khung phát triển; chưa có ứng dụng chạy được.**

## Bắt đầu

- [Gợi ý sản phẩm, repo tham khảo và depth]({RESEARCH}): ADVISORY, chưa chốt stack.
- [Phạm vi](PROJECT.md), [tiến độ](PROGRESS.md), [hướng dẫn agent](AGENTS.md).
- [Quy trình chuẩn](docs/framework/standard-delivery.md), [quickstart](docs/framework/quickstart.md).
- [Áp dụng template và phần còn hoãn](docs/adoption/README.md).

Nguồn: `seeker19110/projects-template` tại `{PIN}`, nhập bằng script copy chính thức.

## Kiểm tra

Cần Git, Bash >=4, Python 3 và jq; Windows dùng Git Bash. Chưa chọn SDK mobile.

```bash
git config core.hooksPath scripts/githooks
bash scripts/dev-task.sh doctor
bash scripts/dev-task.sh gate
```

Gate hiện tại chỉ kiểm tra repository, tài liệu, cấu hình và hooks; không phải app build/scan/OCR.
Thêm lệnh build/typecheck thật khi stack được duyệt. Không commit tài liệu cá nhân hoặc khóa API.
Giấy phép sản phẩm chưa chọn; license nguồn giữ ở `third_party/projects-template.LICENSE`.
''',
        'PROJECT.md': f'''# X-Scanner — Project brief

## Trạng thái

Greenfield / discovery. Chủ dự án: @seeker19110.
Đã duyệt ngày 2026-10-11: lưu nghiên cứu làm gợi ý và áp dụng projects-template.
Mục tiêu sản phẩm: scan tài liệu, xuất PDF hoặc ảnh; nghiên cứu khoảng cách/depth để tăng chất lượng.
Người dùng: người cần số hóa tài liệu; phân khúc cụ thể và nền tảng phát hành chưa chốt.
Outcome: bản scan rõ, đủ và file dùng được; chưa có số đo thực nghiệm.

## Scope hiện tại

Advisory, bộ khung chuẩn, project brief, hướng dẫn agent, gate repository và provenance.
Không có code camera, OCR, PDF engine hoặc mobile app trong lần áp dụng này.

## Gợi ý, không phải quyết định

Xem `{RESEARCH}`. Flutter/native/OpenCV, local-first, Android/iOS,
OCR Việt/Anh, PDF searchable và P0–P4 là ứng viên. Depth không mặc định là phần cứng bắt buộc.
Các ngưỡng 95%, CER 2%, p95 2 giây, 100 trang, giảm chụp lại 15% chưa được nghiệm thu.

## Non-goals

Không tự triển khai roadmap, phát hành, chọn license sản phẩm, thêm X-Agents,
bắt buộc tài khoản/cloud/billing hoặc gọi AI API trả phí.

## Guardrails và quyết định mở

Đặc tả sản phẩm cần kiểm tra bảo toàn bản gốc/nội dung, quyền camera/lưu trữ, retention,
không log/upload tài liệu thật, Unicode Việt, bộ nhớ và fallback depth.
Còn mở: nền tảng, stack/SDK, thiết bị, OCR/PDF engine, giấy phép, threat model và benchmark.

## Gate hiện tại

Doctor/gate qua scripts/dev-task.sh. Build/typecheck app **N/A**, không phải PASS.
Trước feature đầu: spec duyệt, ADR phù hợp, lệnh app thật, SDK ghim phiên bản và review license.
''',
        'PROGRESS.md': '''# X-Scanner — Tiến độ

## 2026-10-11: lưu gợi ý và áp dụng bộ khung

Lưu nghiên cứu ở docs/research/2026-10-11-scanner-product-suggestions.md.
Nhập projects-template theo bản ghim; project brief, hướng dẫn agent và gate riêng.
Bằng chứng thực tế: GitHub Actions và docs/adoption/VERIFICATION.md khi có.

## Chưa thực hiện

Chưa chốt stack hoặc tạo app; chưa chạy mobile build, scan, OCR, depth hoặc benchmark.
Branch protection/ruleset và security gates theo stack chưa xác minh áp dụng.
Release, tự merge, dịch vụ ngoài và tác vụ định kỳ chưa bật. P0–P4 chỉ là gợi ý.
''',
        'CHANGELOG.md': '# Changelog — X-Scanner\n\n## Unreleased — 2026-10-11\n\n- Lưu nghiên cứu scan/PDF/ảnh/OCR/depth làm gợi ý.\n- Áp dụng projects-template, provenance, project brief và gate repository.\n\nChưa có app release.',
        'CONTRIBUTING.md': '# Đóng góp\n\nĐọc PROJECT.md, AGENTS.md và docs/framework/standard-delivery.md.\nMỗi thay đổi theo spec/Work ID; advisory không tự cấp phép triển khai.\nChạy doctor/gate, dùng worktree riêng và chỉ chia việc khi file/contract độc lập.\nKhông commit dữ liệu người dùng/secrets; báo đúng kiểm tra đã chạy và còn thiếu.',
        'SECURITY.md': '# Bảo mật\n\nChưa có app release. Không đưa giấy tờ, OCR, khóa truy cập hoặc chi tiết nhạy cảm vào issue public.\nDùng GitHub private reporting nếu đã bật; hiện chưa xác minh kênh riêng.\nNếu chưa có kênh riêng, chỉ yêu cầu maintainer mở kênh an toàn mà không công khai dữ liệu.',
        'SUPPORT.md': '# Hỗ trợ\n\nGitHub Issues của seeker19110/X-Scanner cho câu hỏi không nhạy cảm.\nBảo mật: đọc SECURITY.md. Chưa có SLA hoặc phiên bản app được hỗ trợ.',
        'GOVERNANCE.md': '# Quản trị\n\nMaintainer: @seeker19110. Quyết định qua PROJECT.md, spec và ADR.\nGợi ý không phải quyết định; mọi kiểm tra cần evidence, không tự phát hành hoặc bật dịch vụ ngoài.',
        '.github/CODEOWNERS': '* @seeker19110',
        'docs/adr/0001-framework-adoption.md': f'''# ADR-0001: Áp dụng projects-template

Date: 2026-10-11. Status: Accepted — framework adoption only.
Chủ repo yêu cầu lưu gợi ý rồi áp template lên repo trống.
Nhập nguồn `{PIN}` bằng copy-framework.sh; giữ docs, hooks, agents, scripts và provenance.
Cá nhân hóa brief/tiến độ, gate repository; hoãn workflow phụ thuộc stack/quyền cài đặt.
Không chọn Flutter/native/OCR/depth engine hoặc X-Agents ở ADR này.
Rollback bằng revert commit adoption/config, giữ research; không force-push.
Nâng cấp sau dùng copy-framework.sh --upgrade và review diff/gate; không tự đồng bộ nguồn.
''',
        'docs/specs/2026-10-11-framework-adoption.md': '''# Framework adoption — X-Scanner

Status: Approved for implementation (framework adoption only).
Approval: chủ repo yêu cầu trực tiếp ngày 2026-10-11: lưu gợi ý và áp dụng projects-template.

## Scope

Advisory, khung ghim commit, cấu hình repo và kiểm chứng. Không app, stack, paid API hoặc release.

## Acceptance criteria

- Research giữ nguyên và đánh dấu ADVISORY.
- Copy chính thức, có commit/manifest và license nguồn.
- PROJECT/PROGRESS/CHANGELOG riêng, không nhận kết quả của template làm kết quả sản phẩm.
- Gate có kiểm tra thật, không báo app build/benchmark PASS.
- Drop-ins chưa phù hợp được giữ inactive, có lý do hoãn; không sửa repo nguồn.

## Verification

`python3 scripts/check-adoption.py --lint`, `python3 scripts/check-adoption.py`,
`bash scripts/test-hooks-gate.sh`, `bash scripts/test-hooks-gate-guard.sh`, doctor và gate.
Evidence ở GitHub Actions; app build/benchmark N/A.

## Rollback

Revert adoption/config commits; giữ research, không force-push.
''',
        'docs/adoption/README.md': f'''# Áp dụng projects-template

Nguồn: https://github.com/seeker19110/projects-template
Commit: `{PIN}`. Ngày: 2026-10-11. Dùng copy-framework.sh chính thức.

## Áp dụng

Docs framework/ops, spec/ADR, hooks/agents/commands, cầu nối agent, engine/scripts chất lượng,
FRAMEWORK-VERSION, Git conventions, PR/issue templates, CODEOWNERS và brief/tiến độ riêng.
License nguồn giữ nguyên ở third_party/projects-template.LICENSE, không chọn license sản phẩm.

## Điều chỉnh

Giữ research ADVISORY; không app scaffold, .nvmrc ép Node, model/context 500k mặc định; giữ Context7 của khung chỉ để tra tài liệu phát triển.
Giữ hooks an toàn; developer cần jq và hooksPath cục bộ. Gate chỉ cho adoption;
build/typecheck N/A có lý do, phải thay trước khi code app.

## Hoãn, không coi là hoàn tất

`deferred-dropins/` giữ .example của CI target, release, maintenance, auto-merge,
CodeQL, Scorecard, secret/dependency scan, Dependabot và ruleset để review theo stack/quyền thực.
Chưa nhập ruleset, xác minh branch protection, chạy security gates theo stack hoặc bật lịch định kỳ.
Repository CI không đại diện chất lượng app hoặc readiness phát hành.

## Nâng cấp

Review commit nguồn mới rồi chạy copy-framework.sh --upgrade, soát manifest/diff/overlay và gate.
Không chạy lại importer một lần trên repo đã có framework.
''',
        '.claude/project-commands.sh': '''#!/usr/bin/env bash
# Reviewed: docs/specs/2026-10-11-framework-adoption.md; assignments only, no secrets.
export gate_tools='bash git python3 jq'
export lint='python3 scripts/check-adoption.py --lint'
export test='python3 scripts/check-adoption.py && bash scripts/test-hooks-gate.sh && bash scripts/test-hooks-gate-guard.sh'
export gate_skip_build_reason='Adoption-only: no application source or chosen SDK; not a mobile build. Replace before product implementation.'
export gate_skip_typecheck_reason='Adoption-only docs and Bash; syntax/JSON checks run in lint. Add real language analysis when the app stack is chosen.'
''',
    }
    for name, content in files.items():
        write(target, name, content)
    (target / 'third_party').mkdir(exist_ok=True)
    shutil.copy2(source / 'LICENSE', target / 'third_party/projects-template.LICENSE')
    with (target / '.gitignore').open('a', encoding='utf-8') as out:
        out.write('\n# X-Scanner local artifacts\n.dart_tool/\n.flutter-plugins-dependencies\nandroid/local.properties\n*.keystore\n*.jks\nscans/\nocr-output/\n.adoption-logs/\n')
    write(target, 'docs/adoption/source.json', json.dumps({
        'repository': 'seeker19110/projects-template', 'commit': PIN, 'date': '2026-10-11',
        'method': 'official copy-framework.sh --no-hooks',
        'research_sha256': hashlib.sha256(original).hexdigest(),
        'scope': 'framework-adoption-only', 'product_stack': None,
    }, indent=2))
    write(target, 'scripts/check-adoption.py', CHECKER)
    if (target / RESEARCH).read_bytes() != original:
        raise RuntimeError('Research changed during adoption')


CHECKER = r'''#!/usr/bin/env python3
"""Check adoption integrity; not a scanner feature or mobile build suite."""
import ast
import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PIN = 'aab9f887ec4acc4480da852cc300978979087f6b'
RESEARCH = 'docs/research/2026-10-11-scanner-product-suggestions.md'

def lint():
    count = 0
    for directory in ('scripts', '.claude/hooks'):
        for path in sorted((ROOT / directory).rglob('*.sh')):
            subprocess.run(['bash', '-n', str(path)], check=True)
            count += 1
    for path in sorted((ROOT / 'scripts').glob('*.py')):
        ast.parse(path.read_text(encoding='utf-8'), filename=str(path))
        count += 1
    for rel in ('.claude/settings.json', 'docs/adoption/source.json'):
        json.loads((ROOT / rel).read_text(encoding='utf-8'))
        count += 1
    for rel in ('README.md', 'PROJECT.md', 'PROGRESS.md', 'CHANGELOG.md'):
        text = (ROOT / rel).read_text(encoding='utf-8')
        if '[ĐIỀN:' in text or 'OWNER-CHANGE-ME' in text:
            raise ValueError(f'Unresolved project placeholder: {rel}')
    print(f'PASS: {count} syntax/configuration checks; no app build or scan benchmark.')

class AdoptionTests(unittest.TestCase):
    def test_source_pin(self):
        info = json.loads((ROOT / 'docs/adoption/source.json').read_text())
        self.assertEqual(info['commit'], PIN)
        stamp = (ROOT / 'docs/framework/FRAMEWORK-VERSION').read_text()
        reference = next(line.split(': ', 1)[1] for line in stamp.splitlines() if line.startswith('commit-nguon: '))
        self.assertGreaterEqual(len(reference), 7)
        self.assertTrue(PIN.startswith(reference))

    def test_research_preserved(self):
        info = json.loads((ROOT / 'docs/adoption/source.json').read_text())
        data = (ROOT / RESEARCH).read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), info['research_sha256'])
        self.assertIn(b'ADVISORY', data)

    def test_required_files(self):
        for rel in ('AGENTS.md', 'CLAUDE.md', 'GEMINI.md', 'PROJECT.md', 'PROGRESS.md',
                    'docs/framework/standard-delivery.md', 'docs/framework/quickstart.md',
                    'scripts/dev-task.sh', 'scripts/githooks/pre-commit',
                    '.claude/project-commands.sh', 'third_party/projects-template.LICENSE'):
            with self.subTest(path=rel):
                self.assertTrue((ROOT / rel).is_file())

    def test_manifest_integrity(self):
        count = 0
        for line in (ROOT / 'docs/framework/FRAMEWORK-VERSION').read_text().splitlines():
            if line.startswith('manifest: '):
                _, digest, relative = line.split(maxsplit=2)
                data = (ROOT / relative).read_bytes()
                actual = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
                self.assertEqual(actual, digest, relative)
                count += 1
        self.assertGreater(count, 0)

    def test_inactive_dropins(self):
        self.assertFalse((ROOT / '_framework-dropins').exists())
        self.assertFalse(list(ROOT.rglob('*.framework-new')))
        self.assertFalse((ROOT / '.nvmrc').exists())
        self.assertTrue((ROOT / '.mcp.json').exists())

    def test_no_forced_model(self):
        settings = json.loads((ROOT / '.claude/settings.json').read_text())
        self.assertNotIn('model', settings)
        self.assertIn('hooks', settings)
        self.assertTrue(settings['permissions']['deny'])

    def test_no_fake_product_completion(self):
        text = (ROOT / 'PROGRESS.md').read_text(encoding='utf-8')
        self.assertIn('Chưa chốt stack', text)
        self.assertNotIn('radar 100/100', text)
        self.assertIn('N/A', (ROOT / 'PROJECT.md').read_text(encoding='utf-8'))
        for directory in ('apps', 'packages', 'android', 'ios'):
            self.assertFalse((ROOT / directory).exists(), 'Configure real product gates before adding application source')

if __name__ == '__main__':
    if sys.argv[1:] == ['--lint']:
        lint()
    else:
        unittest.main(verbosity=2)
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--target', type=Path, default=Path.cwd())
    args = parser.parse_args()
    apply(args.source.resolve(), args.target.resolve())

if __name__ == '__main__':
    main()
