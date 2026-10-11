#!/usr/bin/env python3
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
