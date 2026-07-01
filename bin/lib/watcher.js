import { join } from 'node:path';
import chokidar from 'chokidar';
import { runCodegen, runElmCompile } from './codegen.js';
import { copyElmJson, readShioriJson } from './config.js';
import { logError } from './utils.js';

/** @type {import('chokidar').FSWatcher[]} */
let activeWatchers = [];

/**
 * Starts the file watchers for hot reloading and recompilation.
 * Closes any existing active watchers before starting.
 * @returns {Promise<void>}
 */
export const startWatchers = async () => {
  try {
    for (const w of activeWatchers) {
      await w.close();
    }
    activeWatchers = [];

    const shioriJson = await readShioriJson();
    if (shioriJson) {
      await copyElmJson(shioriJson.roots);
      await runCodegen(shioriJson);

      const w1 = chokidar.watch(shioriJson.roots);
      w1.on('change', async () => {
        await copyElmJson(shioriJson.roots);
        await runCodegen(shioriJson);
      });
      activeWatchers.push(w1);

      const w2 = chokidar.watch(join('elm-stuff', 'shiori', 'src', 'Shiori', 'Route.elm'));
      w2.on('change', async () => await runElmCompile());
      activeWatchers.push(w2);

      const w3 = chokidar.watch(join('elm-stuff', 'shiori', 'src', 'Shiori_View.elm'));
      w3.on('change', async () => await runElmCompile());
      activeWatchers.push(w3);

      const w4 = chokidar.watch(join('elm-stuff', 'shiori', 'src', 'Shiori.elm'));
      w4.on('change', async () => await runElmCompile());
      activeWatchers.push(w4);
    }
  } catch (err) {
    logError(err);
  }
};
