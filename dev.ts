import { join } from 'node:path';
import chokidar from 'chokidar';
const { red, cyan } = require('kleur');
import { readdir } from 'node:fs/promises';

console.log(cyan('== running dev.ts =='));

/**
 * Route.elm
 */
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

/**
 * white shiori.elm
 */
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
