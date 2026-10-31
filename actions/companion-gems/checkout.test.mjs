import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, mkdtempSync, rmSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { checkoutCompanions, planCompanions } from './checkout.mjs';
import { fileURLToPath } from 'node:url';

const revision = 'a'.repeat(40);
const dependency = { repository: 'LegionIO/legion-settings', ref: revision };

function workspace(t) {
  const directory = mkdtempSync(join(tmpdir(), 'companion-gems-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

function options(directory, repositories) {
  return {
    manifest: JSON.stringify(repositories),
    workspace: directory,
    owner: 'LegionIO',
    serverUrl: 'https://github.com',
  };
}

test('rejects a later invalid dependency before creating any checkout', (t) => {
  const directory = workspace(t);
  assert.throws(() => checkoutCompanions(options(directory, {
    'legion-settings': dependency,
    'legion-data': { repository: 'LegionIO/legion-data', ref: 'main' },
  })), /immutable commit SHA/);
  assert.equal(existsSync(join(directory, '.ci-dependencies')), false);
});

test('rejects directory traversal, cross-owner fetches and case-colliding paths', (t) => {
  const directory = workspace(t);
  assert.throws(() => planCompanions(options(directory, { '../outside': dependency })), /directory name/);
  assert.throws(() => planCompanions(options(directory, {
    package: { repository: 'OtherOwner/package', ref: revision },
  })), /must belong/);
  assert.throws(() => planCompanions(options(directory, { Package: dependency, package: dependency })), /Duplicate/);
});

test('does not follow a dangling dependency-root symlink', (t) => {
  const directory = workspace(t);
  const outside = join(directory, 'must-not-be-created');
  symlinkSync(outside, join(directory, '.ci-dependencies'));
  assert.throws(() => checkoutCompanions(options(directory, { package: dependency })), /real directory/);
  assert.equal(existsSync(outside), false);
});

test('never overwrites an existing checkout or follows a target symlink', (t) => {
  const directory = workspace(t);
  const root = join(directory, '.ci-dependencies');
  mkdirSync(join(root, 'existing'), { recursive: true });
  symlinkSync(join(directory, 'outside'), join(root, 'linked'));
  assert.throws(() => checkoutCompanions(options(directory, { existing: dependency })), /already exists/);
  assert.throws(() => checkoutCompanions(options(directory, { linked: dependency })), /already exists/);
});

test('rejects credential-bearing or non-HTTPS server URLs', (t) => {
  const directory = workspace(t);
  assert.throws(() => planCompanions({ ...options(directory, { package: dependency }), serverUrl: 'http://github.com' }), /HTTPS origin/);
  assert.throws(() => planCompanions({ ...options(directory, { package: dependency }), serverUrl: 'https://token@github.com' }), /HTTPS origin/);
});

test('accepts a same-owner immutable commit without mutating the workspace', (t) => {
  const directory = workspace(t);
  const [entry] = planCompanions(options(directory, { 'legion-settings': dependency }));
  assert.equal(entry.remote, 'https://github.com/LegionIO/legion-settings.git');
  assert.equal(entry.ref, revision);
  assert.equal(existsSync(join(directory, '.ci-dependencies')), false);
});

test('CLI validates inputs when invoked through a symlink', (t) => {
  const directory = workspace(t);
  const executable = join(directory, 'checkout.mjs');
  symlinkSync(fileURLToPath(new URL('./checkout.mjs', import.meta.url)), executable);
  const result = spawnSync(process.execPath, [executable], {
    encoding: 'utf8',
    env: {
      ...process.env,
      GITHUB_WORKSPACE: directory,
      GITHUB_REPOSITORY_OWNER: 'LegionIO',
      GITHUB_SERVER_URL: 'https://github.com',
      COMPANION_GEMS: JSON.stringify({ package: { ...dependency, ref: 'main' } }),
    },
  });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /immutable commit SHA/);
  assert.equal(existsSync(join(directory, '.ci-dependencies')), false);
});
