import assert from 'node:assert';
import { exec } from 'node:child_process';
import { test } from 'node:test';
import { promisify } from 'node:util';

const execAsync = promisify(exec);

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
