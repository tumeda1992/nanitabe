import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, chmodSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const source = readFileSync(new URL('./start.sh', import.meta.url), 'utf8');
const stopped = 'http://192.0.2.1:18101/{proxy}';
const stub = `#!${process.execPath}
const fs = require('fs');
const args = process.argv.slice(2);
const state = JSON.parse(fs.readFileSync(process.env.TEST_STATE, 'utf8'));
const save = () => fs.writeFileSync(process.env.TEST_STATE, JSON.stringify(state));
const fail = (phase) => { if (process.env.FAIL_AT === phase) { save(); console.error('test failure: '+phase); process.exit(42); } };
const value = key => args[args.indexOf(key)+1];
const output = (phase, text) => { fail(phase); console.log(process.env.EMPTY_AT === phase ? 'None' : text); };
const name = process.argv[1].split('/').pop();
if (name === 'date') { fail('date'); console.log('2026-11-02T00:30:00'); process.exit(0); }
if (name === 'jq') {
  fail('jq'); const vars = {};
  for(let i=0;i<args.length;i++) if(args[i]==='--arg') { vars[args[i+1]]=args[i+2]; i+=2; }
  const expression=args.at(-1);
  const result=expression.includes('DesiredCount') ? {Cluster:vars.cluster,Service:vars.service,DesiredCount:0} :
    expression.includes('IntegrationUri') ? {ApiId:vars.apiId,IntegrationId:vars.integrationId,IntegrationUri:vars.uri} :
    {Arn:vars.arn,RoleArn:vars.role,Input:vars.input};
  console.log(JSON.stringify(result)); process.exit(0);
}
state.calls.push(args); save();
const command = args.slice(0,2).join(' ');
switch(command) {
case 'ecs describe-services': output('describe',state.desired); break;
case 'ecs update-service': {
  const desired=Number(value('--desired-count'));
  if(desired===0 && process.env.CLEANUP_FAIL==='service') { console.error('cleanup service denied'); process.exit(99); }
  state.desired=desired; save(); if(desired===1) fail('start'); break;
}
case 'ecs wait':
  if(process.env.SIGNAL) { process.kill(process.ppid,process.env.SIGNAL); process.exit(0); }
  fail('wait'); break;
case 'ecs list-tasks': output('tasks','arn:aws:ecs:ap-northeast-1:000000000000:task/example'); break;
case 'ecs describe-tasks': output('eni',value('--query').includes('startedAt') ? '2026-11-01T00:00:00Z' : 'eni-example'); break;
case 'ec2 describe-network-interfaces': output('ip','203.0.113.10'); break;
case 'apigatewayv2 get-apis': output('api','example-api'); break;
case 'apigatewayv2 get-integrations': output('integration-id','example-integration'); break;
case 'apigatewayv2 update-integration':
  if(value('--integration-uri').includes('192.0.2.1')) {
    if(process.env.CLEANUP_FAIL==='integration') { console.error('cleanup integration denied'); process.exit(99); }
    state.uri=value('--integration-uri'); save();
  } else { state.uri=value('--integration-uri'); save(); fail('integration'); }
  break;
case 'iam get-role': output('role','arn:aws:iam::000000000000:role/example'); break;
case 'scheduler delete-schedule':
  fail('delete'); console.error('An error occurred (ResourceNotFoundException): absent'); process.exit(254);
case 'scheduler create-schedule': {
  const target=JSON.parse(value('--target'));
  if(!target.Arn || !target.RoleArn || !target.Input) process.exit(93);
  JSON.parse(target.Input);
  fail(value('--name').endsWith('_integration') ? 'schedule-integration' : 'schedule-service');
  state.schedules.push(value('--name')); save(); break;
}
default: console.error('unexpected AWS operation '+command); process.exit(94);
}
`;

const run = (options = {}) => {
  const directory = mkdtempSync(join(tmpdir(), 'fr027-'));
  try {
    const statePath = join(directory, 'state.json');
    writeFileSync(statePath, JSON.stringify({ desired: Number(options.INITIAL ?? 0), uri: stopped, schedules: [], calls: [] }));
    const envPath = join(directory, 'environment');
    writeFileSync(envPath, 'ROUTE53_HOSTZONE_NAME=example.invalid\n');
    const scriptPath = join(directory, 'start.sh');
    assert.ok(source.includes('/etc/opt/app_setting_files/nanitabe/.env'));
    writeFileSync(scriptPath, source.replaceAll('/etc/opt/app_setting_files/nanitabe/.env', envPath));
    for (const name of ['aws', 'jq', 'date']) {
      const path = join(directory, name);
      writeFileSync(path, stub); chmodSync(path, 0o755);
    }
    const result = spawnSync('bash', [scriptPath], {
      env: { PATH: `${directory}:${process.env.PATH}`, TEST_STATE: statePath, ...options },
      encoding: 'utf8', timeout: 30000,
    });
    assert.ifError(result.error);
    return { ...result, state: JSON.parse(readFileSync(statePath, 'utf8')) };
  } finally { rmSync(directory, { recursive: true, force: true }); }
};

test('successful startup configures both automatic-stop schedules', () => {
  const result = run();
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.state.desired, 1);
  assert.equal(result.state.schedules.length, 2);
  assert.match(result.state.uri, /203\.0\.113\.10/);
});

for (const phase of ['start', 'wait', 'tasks', 'eni', 'ip', 'integration', 'delete', 'schedule-service', 'schedule-integration']) {
  test(`rolls service and integration back after ${phase} fails`, () => {
    const result = run({ FAIL_AT: phase });
    assert.equal(result.status, 42, result.stderr);
    assert.equal(result.state.desired, 0, result.stderr);
    assert.equal(result.state.uri, stopped, result.stderr);
  });
}
for (const phase of ['api', 'integration-id', 'role', 'date', 'jq']) {
  test(`does not leave a service running when ${phase} preparation fails`, () => {
    const result = run({ FAIL_AT: phase });
    assert.notEqual(result.status, 0);
    assert.equal(result.state.desired, 0, result.stderr);
  });
}
test('repairs an already-running service instead of returning before scheduling', () => {
  const result = run({ INITIAL: '1' });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.state.schedules.length, 2);
  assert.match(result.state.uri, /203\.0\.113\.10/);
});
for (const phase of ['role', 'date', 'jq']) {
  test(`stops an already-running service when ${phase} fails during repair`, () => {
    const result = run({ INITIAL: '1', FAIL_AT: phase });
    assert.equal(result.status, 42, result.stderr);
    assert.equal(result.state.desired, 0);
    assert.equal(result.state.uri, stopped);
  });
}
for (const phase of ['api', 'integration-id']) {
  test(`stops service repair even when the ${phase} result is absent`, () => {
    const result = run({ INITIAL: '1', EMPTY_AT: phase });
    assert.notEqual(result.status, 0);
    assert.equal(result.state.desired, 0);
    assert.match(result.stderr, /integration ID/);
  });
}
for (const phase of ['tasks', 'eni', 'ip']) {
  test(`rejects an empty AWS ${phase} result`, () => {
    const result = run({ EMPTY_AT: phase });
    assert.notEqual(result.status, 0);
    assert.equal(result.state.desired, 0);
  });
}
for (const value of ['0', '-1', 'invalid']) {
  test(`rejects invalid stop duration ${value} before starting`, () => {
    const result = run({ REVIEW_BACKEND_AUTO_STOP_MINUTES: value });
    assert.notEqual(result.status, 0);
    assert.equal(result.state.desired, 0);
  });
}
for (const [signal, code] of [['SIGINT', 130], ['SIGTERM', 143]]) {
  test(`rolls back and preserves the exit status on ${signal}`, () => {
    const result = run({ SIGNAL: signal });
    assert.equal(result.status, code, result.stderr);
    assert.equal(result.state.desired, 0);
    assert.equal(result.state.uri, stopped);
  });
}
for (const resource of ['service', 'integration']) {
  test(`attempts both cleanups and reports failure when ${resource} cleanup is denied`, () => {
    const result = run({ FAIL_AT: 'integration', CLEANUP_FAIL: resource });
    assert.equal(result.status, 42, result.stderr);
    assert.match(result.stderr, /rollback|停止.*失敗/i);
    assert.ok(result.state.calls.some((args) => args[0] === 'ecs' && args.includes('0')));
    assert.ok(result.state.calls.some((args) => args.includes(stopped)));
    if (resource === 'service') {
      assert.equal(result.state.desired, 1);
      assert.equal(result.state.uri, stopped);
    } else {
      assert.equal(result.state.desired, 0);
      assert.match(result.state.uri, /203\.0\.113\.10/);
    }
  });
}
