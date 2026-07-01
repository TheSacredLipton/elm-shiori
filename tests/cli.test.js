import assert from 'node:assert';
import { exec } from 'node:child_process';
import { access, mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { test } from 'node:test';
import { promisify } from 'node:util';

const execAsync = promisify(exec);
const shioriPath = resolve('bin/shiori.js');

test('bin/shiori.js displays help content', async () => {
  const { stdout, stderr } = await execAsync('node bin/shiori.js --help');
  assert.match(stdout, /shiori/);
  assert.equal(stderr, '');
});

test('dev.js displays help content', async () => {
  const { stdout, stderr } = await execAsync('node dev.js --help');
  assert.match(stdout, /example/);
  assert.equal(stderr, '');
});

test('shiori init creates shiori.json with schema link', async () => {
  const tempDir = await mkdtemp(join(tmpdir(), 'elm-shiori-test-'));
  try {
    await execAsync(`node ${shioriPath} init`, { cwd: tempDir });
    const jsonPath = join(tempDir, 'shiori.json');

    // Verify file exists
    await assert.doesNotReject(access(jsonPath));

    // Verify content schema property
    const content = JSON.parse(await readFile(jsonPath, 'utf-8'));
    assert.ok(content.$schema);
    assert.match(content.$schema, /shiori\.schema\.json/);
    assert.deepEqual(content.roots, ['src']);
  } finally {
    await rm(tempDir, { recursive: true, force: true });
  }
});

test('shiori build generates build artifacts', async () => {
  const examplePath = resolve('examples/01-hello');
  const targetJs = join(examplePath, 'elm-stuff', 'shiori', 'shiori.js');
  const targetLogo = join(examplePath, 'elm-stuff', 'shiori', 'logo.svg');

  // Clean up any existing build artifacts before test
  await rm(join(examplePath, 'elm-stuff', 'shiori'), { recursive: true, force: true }).catch(
    () => {}
  );

  // Run build
  await execAsync(`node ${shioriPath} build`, { cwd: examplePath });

  // Verify compilation artifacts
  await assert.doesNotReject(access(targetJs));
  await assert.doesNotReject(access(targetLogo));
});
