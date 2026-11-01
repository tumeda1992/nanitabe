import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { spawn } from 'node:child_process';
import test from 'node:test';

const workflow = readFileSync(new URL('../../.github/workflows/backend-deploy.yml', import.meta.url), 'utf8');
const command = workflow.match(/        run: \|\n((?:          .*(?:\n|$))*)/)?.[1];
assert.ok(command, 'the webhook step must have a shell command');

test('bounds connection and total request time without retrying the deployment', () => {
  assert.match(command, /--connect-timeout 10\b/);
  assert.match(command, /--max-time 30\b/);
  assert.doesNotMatch(command, /--retry/);
});

for (const [status, expected] of [[200, 0], [401, 22], [404, 22], [500, 22], ['timeout', 28]]) {
  test(`reports ${status} from the actual workflow curl command`, async () => {
    let requests = 0;
    const server = createServer((req, res) => {
      requests += 1;
      assert.equal(req.method, 'GET');
      assert.equal(req.url, '/webhook/test-token');
      if (status !== 'timeout') res.writeHead(status).end('fixture response');
    });
    await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
    try {
      // Execute the unchanged step except for shortening its total deadline in this fixture.
      const fixtureCommand = command.replace('--max-time 30', '--max-time 0.2');
      const result = await new Promise((resolve, reject) => {
        const child = spawn('bash', ['-e', '-o', 'pipefail', '-c', fixtureCommand], {
          env: {
            PATH: process.env.PATH,
            N8N_WORKFLOW_ORIGIN: `http://127.0.0.1:${server.address().port}`,
            N8N_WORKFLOW_TOKEN: 'test-token',
          },
          stdio: 'ignore',
        });
        const deadline = setTimeout(() => child.kill('SIGTERM'), 3000);
        child.once('error', reject);
        child.once('exit', (code, signal) => { clearTimeout(deadline); resolve({ code, signal }); });
      });
      assert.deepEqual(result, { code: expected, signal: null });
      assert.equal(requests, 1, 'a failed deployment request must not be retried');
    } finally {
      server.closeAllConnections();
      await new Promise((resolve) => server.close(resolve));
    }
  });
}
