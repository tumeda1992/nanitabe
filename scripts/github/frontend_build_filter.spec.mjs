import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const workflowPath = '.github/workflows/ci-frontend-build-verification.yml';
const workflow = readFileSync(new URL(`../../${workflowPath}`, import.meta.url), 'utf8');
const script = workflow.match(/      - name: Detect frontend changes[\s\S]*?        run: \|\n([\s\S]*?)(?=\n      - name:)/)?.[1];
assert.ok(script, 'the change-detection step must exist');

for (const [files, changed] of [['frontend/src/app/page.tsx', true], [workflowPath, true], ['backend/app/models/dish.rb\nREADME.md', false]]) {
  test(`detects ${files.replaceAll('\n', ', ')} as changed=${changed}`, () => {
    const directory = mkdtempSync(join(tmpdir(), 'fr030-'));
    try {
      const output = join(directory, 'output');
      const git = join(directory, 'git');
      writeFileSync(git, '#!/bin/bash\ncase "$1" in\n  merge-base) echo fixture-base ;;\n  diff) printf "%s\\n" "$CHANGED_FIXTURE" ;;\n  *) exit 91 ;;\nesac\n', { mode: 0o755 });
      const result = spawnSync('bash', ['-e', '-o', 'pipefail', '-c', script.replace('${{ github.base_ref }}', 'main')], {
        env: { PATH: `${directory}:${process.env.PATH}`, GITHUB_OUTPUT: output, CHANGED_FIXTURE: files },
        encoding: 'utf8', timeout: 10000,
      });
      assert.ifError(result.error);
      assert.equal(result.status, 0, result.stderr);
      assert.equal(readFileSync(output, 'utf8'), `changed=${changed}\n`);
    } finally { rmSync(directory, { recursive: true, force: true }); }
  });
}
