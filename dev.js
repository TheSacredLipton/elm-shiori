import { spawn } from 'node:child_process';
import { mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import chokidar from 'chokidar';
import kleur from 'kleur';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';

const { red, cyan } = kleur;

const __dirname = fileURLToPath(new URL('.', import.meta.url));

/**
 * Route.elm
 */
const writeRouteElm = async () => {
  const route_elm = `module Shiori.Route exposing (..)


links =
    []


view _ =
    []
`;
  try {
    const destDir = join(__dirname, 'core', 'shiori', 'src', 'Shiori');
    await mkdir(destDir, { recursive: true });
    await writeFile(join(destDir, 'Route.elm'), route_elm);
  } catch (error) {
    console.error(red(`Error writing Route.elm: ${error}`));
  }
};

/**
 * write shiori.elm
 * @param {string} example
 */
const writeShioriElm = async example => {
  // Initial copy
  try {
    const shiori_elm = await readFile(
      join(__dirname, 'core', 'shiori', 'src', 'Shiori.elm'),
      'utf-8'
    );
    await writeFile(
      join(__dirname, 'examples', example, 'elm-stuff', 'shiori', 'src', 'Shiori.elm'),
      shiori_elm
    );

    const index_html = await readFile(join(__dirname, 'core', 'shiori', 'index.html'), 'utf-8');
    await writeFile(
      join(__dirname, 'examples', example, 'elm-stuff', 'shiori', 'index.html'),
      index_html
    );

    const logo_svg = await readFile(join(__dirname, 'core', 'shiori', 'logo.svg'), 'utf-8');
    await writeFile(
      join(__dirname, 'examples', example, 'elm-stuff', 'shiori', 'logo.svg'),
      logo_svg
    );
  } catch (error) {
    console.error(red(`Error during initial file handling: ${error}`));
  }

  chokidar.watch(join(__dirname, 'core', 'shiori', 'src', 'Shiori.elm')).on('change', async () => {
    try {
      const shiori_elm = await readFile(
        join(__dirname, 'core', 'shiori', 'src', 'Shiori.elm'),
        'utf-8'
      );
      await writeFile(
        join(__dirname, 'examples', example, 'elm-stuff', 'shiori', 'src', 'Shiori.elm'),
        shiori_elm
      );
    } catch (error) {
      console.error(red(`Error during file handling: ${error}`));
    }
  });

  chokidar.watch(join(__dirname, 'core', 'shiori', 'index.html')).on('change', async () => {
    try {
      const index_html = await readFile(join(__dirname, 'core', 'shiori', 'index.html'), 'utf-8');
      await writeFile(
        join(__dirname, 'examples', example, 'elm-stuff', 'shiori', 'index.html'),
        index_html
      );
    } catch (error) {
      console.error(red(`Error during index.html handling: ${error}`));
    }
  });

  chokidar.watch(join(__dirname, 'core', 'shiori', 'logo.svg')).on('change', async () => {
    try {
      const logo_svg = await readFile(join(__dirname, 'core', 'shiori', 'logo.svg'), 'utf-8');
      await writeFile(
        join(__dirname, 'examples', example, 'elm-stuff', 'shiori', 'logo.svg'),
        logo_svg
      );
    } catch (error) {
      console.error(red(`Error during logo.svg handling: ${error}`));
    }
  });
};

/**
 * @param {string} name
 */
const runShioriJs = async name => {
  const examplePath = join('examples', name);
  try {
    /** @type {any} */
    const child = spawn('node', ['--watch', '../../bin/shiori.js', 'serve'], {
      cwd: examplePath,
      stdio: 'inherit',
      shell: true
    });
    child.on(
      'error',
      /** @param {Error} error */ error => {
        console.error(red(`Error running shiori.js: ${error}`));
      }
    );
  } catch (error) {
    console.error(red(`Error during file handling: ${error}`));
  }
};

const argv = yargs(hideBin(process.argv))
  .command('* <example>', '=== commands === \n\n init \n start')
  .positional('example', {
    describe: 'example name',
    type: 'string',
    demandOption: true
  })
  .parseSync();

(async () => {
  const examples = await readdir(join(__dirname, 'examples'));
  const example = argv.example;
  if (typeof example === 'string' && examples.includes(example)) {
    console.log(cyan('== running dev.js =='));
    await writeRouteElm();
    await writeShioriElm(example);
    await runShioriJs(example);
  } else {
    console.log(examples);
    console.error(red(`${example}はありません`));
  }
})();
