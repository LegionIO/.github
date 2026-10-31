import { execFileSync } from 'node:child_process';
import { lstatSync, mkdirSync, realpathSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

export function planCompanions({ manifest, workspace, owner, serverUrl }) {
  const repositories = JSON.parse(manifest);
  if (!repositories || Array.isArray(repositories) || typeof repositories !== 'object') {
    throw new Error('Companion repositories must be a JSON object');
  }
  if (!workspace || !owner || !serverUrl) {
    throw new Error('GitHub workspace, repository owner and server URL are required');
  }
  const server = new URL(serverUrl);
  if (server.protocol !== 'https:' || server.username || server.password || server.search || server.hash || server.pathname !== '/') {
    throw new Error('GitHub server URL must be an HTTPS origin');
  }
  const root = join(realpathSync(workspace), '.ci-dependencies');
  try {
    const rootStat = lstatSync(root);
    if (rootStat.isSymbolicLink() || !rootStat.isDirectory()) {
      throw new Error('Companion checkout root must be a real directory');
    }
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
  const directoryNames = new Set();

  return Object.entries(repositories).map(([name, specification]) => {
    if (!/^[a-zA-Z0-9][a-zA-Z0-9_.-]*$/.test(name)) {
      throw new Error(`Invalid companion directory name: ${name}`);
    }
    if (directoryNames.has(name.toLowerCase())) {
      throw new Error(`Duplicate companion directory name: ${name}`);
    }
    directoryNames.add(name.toLowerCase());
    if (!specification || Array.isArray(specification) || typeof specification !== 'object' ||
        Object.keys(specification).some((key) => !['repository', 'ref'].includes(key))) {
      throw new Error(`Invalid companion specification: ${name}`);
    }
    const { repository, ref } = specification;
    if (typeof repository !== 'string' || !/^[a-zA-Z0-9][a-zA-Z0-9-]*\/[a-zA-Z0-9_.-]+$/.test(repository) ||
        ['.', '..'].includes(repository.split('/')[1])) {
      throw new Error(`Invalid companion repository: ${name}`);
    }
    if (repository.split('/')[0].toLowerCase() !== owner.toLowerCase()) {
      throw new Error(`Companion repository must belong to ${owner}: ${repository}`);
    }
    if (typeof ref !== 'string' || !/^[a-fA-F0-9]{40}$/.test(ref)) {
      throw new Error(`Companion ref must be a full immutable commit SHA: ${name}`);
    }
    const directory = join(root, name);
    // lstat catches dangling symlinks too; never follow or overwrite a checkout.
    try {
      lstatSync(directory);
      throw new Error(`Companion checkout destination already exists: ${name}`);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    return { name, repository, ref: ref.toLowerCase(), directory, remote: `${server.origin}/${repository}.git` };
  });
}

export function checkoutCompanions(options) {
  // Validate the entire manifest before creating directories or fetching anything.
  const plan = planCompanions(options);
  for (const entry of plan) {
    mkdirSync(entry.directory, { recursive: true });
    const git = (args, capture = false) => execFileSync('git', ['-C', entry.directory, ...args], {
      stdio: capture ? ['ignore', 'pipe', 'inherit'] : ['ignore', 'inherit', 'inherit'],
      encoding: 'utf8',
      timeout: 120_000,
      env: { ...process.env, GIT_TERMINAL_PROMPT: '0' },
    });
    git(['init', '--quiet']);
    git(['-c', 'protocol.file.allow=never', '-c', 'protocol.ext.allow=never', 'fetch', '--no-tags', '--depth=1', entry.remote, entry.ref]);
    git(['-c', 'core.hooksPath=/dev/null', 'checkout', '--quiet', '--detach', 'FETCH_HEAD']);
    const actual = git(['rev-parse', 'HEAD'], true).trim();
    if (actual !== entry.ref) throw new Error(`Companion commit mismatch: ${entry.name}`);
    console.log(`Companion ${entry.repository}@${actual} available at ${entry.directory}`);
  }
  return plan;
}

if (process.argv[1] && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    checkoutCompanions({
      manifest: process.env.COMPANION_GEMS || '{}',
      workspace: process.env.GITHUB_WORKSPACE,
      owner: process.env.GITHUB_REPOSITORY_OWNER,
      serverUrl: process.env.GITHUB_SERVER_URL,
    });
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
