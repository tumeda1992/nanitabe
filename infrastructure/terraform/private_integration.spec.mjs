import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const read = (path) => readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8');
const ecs = read('backend/terraform/modules/ecs/main.tf');
const api = read('backend/terraform/modules/apigateway/main.tf');
const scheduler = read('backend/terraform/modules/scheduler_role/main.tf');
const wiring = read('backend/terraform/envs/review/main.tf');
const block = (source, kind, name) => {
  const body = source.match(new RegExp(`resource "${kind}" "${name}" \\{([\\s\\S]*?)\\n\\}`))?.[1];
  assert.ok(body, `${kind}.${name} must exist`);
  return body;
};

test('accepts task traffic only from the VPC link security group', () => {
  const task = block(ecs, 'aws_security_group', 'task');
  const ingress = task.match(/ingress \{([\s\S]*?)\n  \}/)?.[1];
  assert.ok(ingress);
  assert.match(ingress, /security_groups\s*=\s*\[aws_security_group\.vpc_link\.id\]/);
  assert.doesNotMatch(ingress, /cidr_blocks|ipv6_cidr_blocks|self\s*=/);
  assert.match(ingress, /from_port\s*=\s*local\.container_port/);
  assert.match(ingress, /to_port\s*=\s*local\.container_port/);
  assert.match(block(ecs, 'aws_security_group', 'vpc_link'), /vpc_id\s*=\s*data\.aws_vpc\.default\.id/);
});

test('registers healthy task IP and port in a private SRV service', () => {
  assert.match(block(ecs, 'aws_service_discovery_private_dns_namespace', 'backend'), /vpc\s*=\s*data\.aws_vpc\.default\.id/);
  const discovery = block(ecs, 'aws_service_discovery_service', 'backend');
  assert.match(discovery, /namespace_id\s*=\s*aws_service_discovery_private_dns_namespace\.backend\.id/);
  assert.match(discovery, /type\s*=\s*"SRV"/);
  assert.match(discovery, /health_check_custom_config/);
  assert.match(block(ecs, 'aws_ecs_service', 'this'), /service_registries\s*\{\s*registry_arn\s*=\s*aws_service_discovery_service\.backend\.arn/);
  assert.match(ecs, /healthCheck\s*=\s*\{/);
  assert.match(ecs, /TCPSocket/);
});

test('uses a fixed private integration and preserves backend path and Host', () => {
  const link = block(api, 'aws_apigatewayv2_vpc_link', 'this');
  assert.match(link, /security_group_ids\s*=\s*\[var\.vpc_link_security_group_id\]/);
  assert.match(link, /subnet_ids\s*=\s*var\.vpc_link_subnet_ids/);
  const integration = block(api, 'aws_apigatewayv2_integration', 'this');
  assert.match(integration, /connection_type\s*=\s*"VPC_LINK"/);
  assert.match(integration, /connection_id\s*=\s*aws_apigatewayv2_vpc_link\.this\.id/);
  assert.match(integration, /integration_uri\s*=\s*var\.discovery_service_arn/);
  assert.match(integration, /"overwrite:path"\s*=\s*"\$request\.path"/);
  assert.match(integration, /"overwrite:header\.Host"\s*=\s*local\.custom_domain/);
  assert.doesNotMatch(api, /stopped_integration_uri|ignore_changes\s*=\s*\[integration_uri\]/);
});

test('keeps existing egress, task size, secrets, and ARM platform without adding a load balancer', () => {
  assert.match(ecs, /assign_public_ip\s*=\s*true/);
  assert.match(ecs, /cpu\s*=\s*"256"/);
  assert.match(ecs, /memory\s*=\s*"512"/);
  assert.match(ecs, /cpu_architecture\s*=\s*"ARM64"/);
  assert.match(ecs, /name\s*=\s*"RAILS_MASTER_KEY", valueFrom\s*=\s*local\.rails_master_key_arn/);
  assert.doesNotMatch(ecs + api, /resource "aws_(lb|nat_gateway|eip)"/);
});

test('wires discovery to the integration and removes obsolete scheduler API privileges', () => {
  assert.match(wiring, /discovery_service_arn\s*=\s*module\.ecs\.discovery_service_arn/);
  assert.match(wiring, /vpc_link_security_group_id\s*=\s*module\.ecs\.vpc_link_security_group_id/);
  assert.match(wiring, /vpc_link_subnet_ids\s*=\s*module\.ecs\.vpc_link_subnet_ids/);
  assert.match(scheduler, /Action\s*=\s*\["ecs:UpdateService"\]/);
  assert.doesNotMatch(scheduler, /apigateway:PATCH|apigateway:GET|var\.api_id/);
  const schedulerWiring = wiring.match(/module "scheduler_role" \{([\s\S]*?)\n\}/)?.[1];
  assert.ok(schedulerWiring);
  assert.doesNotMatch(schedulerWiring, /api_id/);
});

test('never rewrites the fixed integration at runtime and cleans up legacy schedules', () => {
  for (const file of ['start.sh', 'stop.sh']) {
    const script = read(`scripts/review_backend/${file}`);
    assert.doesNotMatch(script, /update-integration|describe-network-interfaces|target_stop_integration/);
    assert.match(script, /delete_schedule_if_exists "\$SCHEDULE_STOP_INTEGRATION"/);
  }
});
