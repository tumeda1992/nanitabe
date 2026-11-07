import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const source = readFileSync(new URL('./main.tf', import.meta.url), 'utf8');
const document = source.match(/data "aws_iam_policy_document" "plan_state_access" \{([\s\S]*?)\n\}/)?.[1];
assert.ok(document, 'plan inline policy must exist');
const bucket = 'arn:aws:s3:::example-state';
const table = 'arn:aws:dynamodb:ap-northeast-1:000000000000:table/example-lock';
const values = (expression) => {
  if (expression.trim() === 'local.state_bucket_arn') return [bucket];
  if (expression.trim() === 'local.lock_table_arn') return [table];
  return [...expression.matchAll(/"([^"]+)"/g)].map(([, value]) => value.replaceAll('${local.state_bucket_arn}', bucket));
};
const statements = [...document.matchAll(/statement \{([\s\S]*?)\n  \}/g)].map(([, body]) => ({
  effect: body.match(/effect\s*=\s*"([^"]+)"/)[1],
  actions: values(body.match(/actions\s*=\s*\[([^\]]+)\]/)[1]),
  resources: values(body.match(/resources\s*=\s*\[([^\]]+)\]/)[1]),
}));
const matches = (pattern, value) => new RegExp(`^${pattern.split('*').map((part) => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('.*')}$`).test(value);
const allowed = (action, resource) => statements.some((statement) => statement.effect === 'Allow' &&
  statement.actions.some((pattern) => matches(pattern.toLowerCase(), action.toLowerCase())) &&
  statement.resources.some((pattern) => matches(pattern, resource)));

test('allows plan logs but denies writes to state, apply logs, and unrelated objects', () => {
  for (const key of ['plans/review/123.txt', 'plans/prod/123.txt']) {
    assert.equal(allowed('s3:PutObject', `${bucket}/${key}`), true, key);
  }
  for (const key of ['prod/terraform.tfstate', 'review/terraform.tfstate', 'terraform.tfstate', 'applies/review/123.txt', 'other/123.txt']) {
    assert.equal(allowed('s3:PutObject', `${bucket}/${key}`), false, key);
    assert.equal(allowed('s3:DeleteObject', `${bucket}/${key}`), false, key);
  }
});

test('retains state reads and DynamoDB lock operations without permitting other tables', () => {
  assert.equal(allowed('s3:GetObject', `${bucket}/review/terraform.tfstate`), true);
  assert.equal(allowed('s3:ListBucket', bucket), true);
  for (const action of ['dynamodb:GetItem', 'dynamodb:PutItem', 'dynamodb:DeleteItem']) {
    assert.equal(allowed(action, table), true, action);
    assert.equal(allowed(action, `${table}-other`), false, action);
  }
});

test('wires the restricted inline document and ReadOnlyAccess to the plan role', () => {
  assert.match(source, /resource "aws_iam_role_policy" "plan_state_access" \{\s*name[^\n]+\n\s*role\s*=\s*aws_iam_role\.plan\.id\s*policy\s*=\s*data\.aws_iam_policy_document\.plan_state_access\.json/);
  assert.match(source, /resource "aws_iam_role_policy_attachment" "plan_read_only" \{\s*role\s*=\s*aws_iam_role\.plan\.name\s*policy_arn\s*=\s*"arn:aws:iam::aws:policy\/ReadOnlyAccess"/);
});
