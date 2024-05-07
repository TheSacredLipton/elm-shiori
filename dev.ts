import { join } from 'node:path';
import chokidar from 'chokidar';
const { red, cyan } = require('kleur');
import { readdir } from 'node:fs/promises';
const yargs = require('yargs');
import { $ } from 'bun';
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
    await Bun.write(
      join(import.meta.dir, 'boilerplate', 'shiori', 'src', 'Shiori', 'Route.elm'),
      route_elm
    );
  } catch (error) {
    console.error(red(`Error writing Route.elm: ${error}`));
  }
};

/**
 * white shiori.elm
 */
const writeShioriElm = () => {
  chokidar
    .watch(join(import.meta.dir, 'boilerplate', 'shiori', 'src', 'Shiori.elm'))
    .on('change', async () => {
      try {
        const examples = await readdir(join(import.meta.dir, 'examples'));
        const shiori_elm = Bun.file(
          join(import.meta.dir, 'boilerplate', 'shiori', 'src', 'Shiori.elm')
        );
        for (const example of examples) {
          await Bun.write(
            join(import.meta.dir, 'examples', example, 'shiori', 'src', 'Shiori.elm'),
            shiori_elm
          );
        }
      } catch (error) {
        console.error(red(`Error during file handling: ${error}`));
      }
    });
};

const runShioriTs = async (name: string) => {
  const examplePath = join('examples', name);
  try {
    await $`(cd ${examplePath} && bun --watch ../../bin/shiori.ts serve)`;
  } catch (error) {
    console.error(red(`Error during file handling: ${error}`));
  }
};

const args: { example: string } = yargs
  .command('* <example>', '=== commands === \n\n init \n start')
  .positional('example', {
    describe: 'example',
    type: 'string',
    demandOption: true
  })
  .parseSync();
(async () => {
  const examples = await readdir(join(import.meta.dir, 'examples'));
  if (examples.includes(args.example)) {
    console.log(cyan('== running dev.ts =='));
    if (args.example) {
      await writeRouteElm();
      writeShioriElm();
      await runShioriTs(args.example);
    }
  } else {
    console.log(examples);
    console.error(red(`${args.example}はありません`));
  }
})();
