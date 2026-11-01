import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, chmodSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const sources = Object.fromEntries(['start.sh', 'stop.sh', 'common.sh'].map((name) => [name, readFileSync(new URL(`./${name}`, import.meta.url), 'utf8')]));
const stubs = readFileSync(new URL('./spec_helpers/cli_stubs.sh', import.meta.url), 'utf8');
const serviceSchedule = 'nanitabe-back_review_auto_stop_service';
const legacySchedule = 'nanitabe-back_review_auto_stop_integration';
const realJq = process.env.PATH.split(':').map((directory) => join(directory, 'jq')).find(existsSync);
assert.ok(realJq, 'jq must be installed to validate the real JSON expressions');
const run = (options = {}, script = 'start.sh') => {
  const directory = mkdtempSync(join(tmpdir(), 'fr028-'));
  try {
    for (const [file, value] of Object.entries({ desired: options.INITIAL ?? '0', vpc_reads: '0', discovery_reads: '0', curl_calls: '0', calls: '', schedules: options.EXISTING_SCHEDULES ? `${serviceSchedule}\n${legacySchedule}\n` : '' })) {
      writeFileSync(join(directory, file), value);
    }
    const envPath = join(directory, 'environment');
    writeFileSync(envPath, 'ROUTE53_HOSTZONE_NAME=example.invalid\n');
    for (const [name, source] of Object.entries(sources)) {
      writeFileSync(join(directory, name), source.replaceAll('/etc/opt/app_setting_files/nanitabe/.env', envPath));
    }
    writeFileSync(join(directory, 'stubs.sh'), stubs);
    for (const name of ['aws', 'curl']) {
      writeFileSync(join(directory, name), '#!/bin/bash\necho "unstubbed command" >&2\nexit 96\n');
      chmodSync(join(directory, name), 0o755);
    }
    const result = spawnSync('bash', [join(directory, script)], {
      env: { PATH: `${directory}:${process.env.PATH}`, BASH_ENV: join(directory, 'stubs.sh'), TEST_DIRECTORY: directory, TEST_JQ: realJq, ...options },
      encoding: 'utf8', timeout: 30000,
    });
    assert.ifError(result.error);
    const state = {
      desired: Number(readFileSync(join(directory, 'desired'), 'utf8')),
      calls: readFileSync(join(directory, 'calls'), 'utf8').split('\u001e').filter(Boolean).map((record) => record.split('\0').filter(Boolean)),
      schedules: readFileSync(join(directory, 'schedules'), 'utf8').trim().split('\n').filter(Boolean),
      curlCalls: Number(readFileSync(join(directory, 'curl_calls'), 'utf8')),
    };
    assert.ok(state.calls.every((args) => !['update-integration', 'describe-network-interfaces'].includes(args[1])), 'runtime must never rewrite private routing');
    return { ...result, state };
  } finally { rmSync(directory, { recursive: true, force: true }); }
};
const arg = (args, key) => args[args.indexOf(key) + 1];

test('starts the private backend and creates only the ECS stop schedule', () => {
  const result = run({ EXISTING_SCHEDULES: '1' });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.state.desired, 1);
  assert.deepEqual(result.state.schedules, [serviceSchedule]);
  const scheduled = result.state.calls.filter((args) => args[0] === 'scheduler' && args[1] === 'create-schedule');
  assert.equal(scheduled.length, 1);
  const target = JSON.parse(arg(scheduled[0], '--target'));
  assert.equal(target.Arn, 'arn:aws:scheduler:::aws-sdk:ecs:updateService');
  assert.deepEqual(JSON.parse(target.Input), { Cluster: 'nanitabe-back-review', Service: 'nanitabe-back_service_review', DesiredCount: 0 });
  assert.equal(arg(scheduled[0], '--schedule-expression'), 'at(2026-11-02T00:30:00)');
  assert.equal(arg(scheduled[0], '--action-after-completion'), 'DELETE');
  assert.equal(arg(scheduled[0], '--schedule-expression-timezone'), 'UTC');
  assert.match(result.stdout, /起動完了/);
  const request = result.state.calls.find((args) => args[0] === 'curl');
  assert.equal(arg(request, '--request'), 'POST');
  assert.equal(JSON.parse(arg(request, '--data')).query, 'query ReviewBackendReadiness { __typename }');
});
for (const phase of ['start', 'wait', 'discovery', 'vpc-link-status', 'delete', 'date', 'schedule-service']) {
  test(`rolls startup back and preserves status when ${phase} fails`, () => {
    const result = run({ FAIL_AT: phase });
    assert.equal(result.status, 42, result.stderr);
    assert.equal(result.state.desired, 0, result.stderr);
    assert.doesNotMatch(result.stdout, /起動完了/);
  });
}
for (const phase of ['api', 'vpc-link-id', 'private-integration', 'role', 'jq']) {
  test(`does not start when ${phase} preparation fails`, () => {
    const result = run({ FAIL_AT: phase });
    assert.equal(result.status, 42, result.stderr);
    assert.equal(result.state.desired, 0);
    assert.ok(!result.state.calls.some((args) => args[1] === 'update-service' && arg(args, '--desired-count') === '1'));
  });
}
test('repairs an already-running private backend and refreshes its schedule', () => {
  const result = run({ INITIAL: '1', EXISTING_SCHEDULES: '1' });
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.state.schedules, [serviceSchedule]);
  assert.ok(!result.state.calls.some((args) => args[1] === 'update-service' && arg(args, '--desired-count') === '1'));
});
for (const phase of ['role', 'date', 'jq', 'discovery']) {
  test(`stops an already-running backend when repair fails at ${phase}`, () => {
    const result = run({ INITIAL: '1', FAIL_AT: phase });
    assert.equal(result.status, 42, result.stderr);
    assert.equal(result.state.desired, 0);
  });
}
for (const phase of ['api', 'vpc-link-id', 'private-integration', 'discovery', 'vpc-link-status']) {
  test(`rejects an absent ${phase} value and stops a running backend`, () => {
    const result = run({ INITIAL: '1', EMPTY_AT: phase });
    assert.notEqual(result.status, 0, result.stderr);
    assert.equal(result.state.desired, 0);
  });
}
for (const options of [{ HEALTHY_COUNT: '0' }, { VPC_STATUS: 'INACTIVE' }, { VPC_STATUS: 'FAILED' }, { CURL_STATUS: '503' }, { FAIL_AT: 'curl' }, { CURL_STATUS: '403' }]) {
  test(`does not report readiness for ${JSON.stringify(options)}`, () => {
    const result = run(options);
    assert.notEqual(result.status, 0, result.stderr);
    assert.equal(result.state.desired, 0);
    assert.doesNotMatch(result.stdout, /起動完了/);
  });
}
test('waits for healthy discovery and for an inactive VPC link to recover', () => {
  const result = run({ UNHEALTHY_CYCLES: '1', INACTIVE_CYCLES: '1' });
  assert.equal(result.status, 0, result.stderr);
  assert.ok(result.state.curlCalls >= 2);
});
for (const status of ['400', '401', '404', '405']) {
  test(`does not mistake HTTP ${status} for a successful GraphQL readiness response`, () => {
    const result = run({ CURL_STATUS: status });
    assert.notEqual(result.status, 0, result.stderr);
    assert.equal(result.state.desired, 0);
  });
}
for (const body of ['not JSON', '{"message":"Not Found"}', '{"data":{"__typename":"Wrong"}}', '{"data":{"__typename":"Query"},"errors":[{"message":"not ready"}]}']) {
  test(`does not identify a non-GraphQL readiness body as success: ${body}`, () => {
    const result = run({ CURL_BODY: body });
    assert.notEqual(result.status, 0, result.stderr);
    assert.equal(result.state.desired, 0);
  });
}
test('rejects the old public integration before activating a stopped service', () => {
  const result = run({ PUBLIC_INTEGRATION: '1' });
  assert.notEqual(result.status, 0);
  assert.equal(result.state.desired, 0);
});
for (const value of ['0', '-1', 'invalid']) {
  test(`rejects invalid automatic-stop duration ${value}`, () => {
    const result = run({ REVIEW_BACKEND_AUTO_STOP_MINUTES: value });
    assert.notEqual(result.status, 0);
    assert.equal(result.state.desired, 0);
  });
}
for (const [signal, code] of [['SIGINT', 130], ['SIGTERM', 143]]) {
  test(`preserves ${signal} status and rolls back`, () => {
    const result = run({ SIGNAL: signal });
    assert.equal(result.status, code, result.stderr);
    assert.equal(result.state.desired, 0);
  });
}
test('reports denied rollback without claiming successful startup', () => {
  const result = run({ FAIL_AT: 'discovery', CLEANUP_FAIL: 'service' });
  assert.equal(result.status, 42, result.stderr);
  assert.equal(result.state.desired, 1);
  assert.match(result.stderr, /停止に失敗/);
  assert.doesNotMatch(result.stdout, /起動完了/);
});
for (const initial of ['0', '1']) {
  test(`stops a backend initially at ${initial}, waits for exit, and removes legacy schedules`, () => {
    const result = run({ INITIAL: initial, EXISTING_SCHEDULES: '1' }, 'stop.sh');
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.state.desired, 0);
    assert.deepEqual(result.state.schedules, []);
    assert.ok(result.state.calls.some((args) => args[0] === 'ecs' && args[1] === 'wait'));
  });
}
for (const options of [{ CLEANUP_FAIL: 'service' }, { FAIL_AT: 'wait' }, { FAIL_AT: 'delete' }]) {
  test(`reports failed stopping for ${JSON.stringify(options)}`, () => {
    const result = run({ INITIAL: '1', EXISTING_SCHEDULES: '1', ...options }, 'stop.sh');
    assert.notEqual(result.status, 0, result.stderr);
    assert.doesNotMatch(result.stdout, /停止完了/);
    assert.ok(result.state.schedules.includes(serviceSchedule), 'retain automatic stop as a fallback');
  });
}
