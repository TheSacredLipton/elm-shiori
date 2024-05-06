import { join } from 'node:path';
import chokidar from 'chokidar';
const { red, cyan } = require('kleur');
const shioriRoot = (): string => join(__dirname, '..');

const routeElm = `module Shiori.Route exposing (..)


links =
    []


view _ =
    []
`;
await Bun.write(join('boilerplate', 'shiori', 'src', 'Shiori', 'Route.elm'), routeElm);

console.log(cyan('== running dev.ts =='));

chokidar
  .watch(join(shioriRoot(), 'boilerplate', 'shiori', 'src', 'Shiori.elm'))
  .on('change', async () => {
    console.log('test');
  });
