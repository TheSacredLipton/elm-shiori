import { exec } from 'node:child_process';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import kleur from 'kleur';

export const execAsync = promisify(exec);

export const { red, cyan } = kleur;

const __dirname = fileURLToPath(new URL('.', import.meta.url));

/**
 * Returns the root directory of the shiori package.
 * @returns {string}
 */
export const shioriRoot = () => join(__dirname, '..', '..');

/**
 * Logs an error message.
 * @param {unknown} error
 * @param {string} [prefix]
 */
export function logError(error, prefix) {
  if (error instanceof Error) {
    if (prefix) {
      console.log(red(`${prefix}: ${error.toString()}`));
    } else {
      console.log(red(error.toString()));
    }
  } else {
    console.log(red('An unknown error occurred'));
  }
}
