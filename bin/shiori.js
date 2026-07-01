#!/usr/bin/env node

import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { serve as honoServe } from '@hono/node-server';
import { serveStatic } from '@hono/node-server/serve-static';
import chokidar from 'chokidar';
import { run_generation_from_cli } from 'elm-codegen/dist/run.js';
import fse from 'fs-extra';
import { Hono } from 'hono';
import { produce } from 'immer';
import kleur from 'kleur';
import compiler from 'node-elm-compiler';
import { WebSocketServer } from 'ws';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';

const { compile } = compiler;
const { red, cyan } = kleur;

/**
 * @typedef {Object.<string, string>} ElmFiles
 * @typedef {Object} ShioriJson
 * @property {string[]} roots
 * @property {ElmFiles} files
 * @property {string} assets
 * @typedef {Object} ElmJson
 * @property {string[]} source-directories
 */

const __dirname = fileURLToPath(new URL('.', import.meta.url));

// パッケージとして使う場合 ./node_modules/elm-shiori になるはず
const shioriRoot = () => join(__dirname, '..');

/**
 * Reads and parses the 'elm.json' file, checking for the 'source-directories' property.
 * @returns {Promise<ElmJson | null>}
 */
const readElmJson = async () => {
  try {
    try {
      const json = JSON.parse(await readFile('elm.json', 'utf-8'));
      if (json['source-directories']) return json;
      throw new Error('elm.jsonにsource-directoriesがありません');
    } catch (error) {
      throw new Error(`${error}elm.jsonが存在しません`);
    }
  } catch (error) {
    logError(error);
    return null;
  }
};

/**
 * Reads and parses the 'shiori.json' file, ensuring it has both 'files' and 'roots' properties.
 * @returns {Promise<ShioriJson | null>}
 */
const readShioriJson = async () => {
  try {
    try {
      const json = JSON.parse(await readFile('shiori.json', 'utf-8'));
      if (json.files && json.roots) return json;
      throw new Error('shiori.jsonにfilesまたはrootがありません');
    } catch (error) {
      throw new Error(`${error}shiori.jsonが存在しません`);
    }
  } catch (error) {
    logError(error);
    return null;
  }
};

/**
 * Reads contents of files specified in the list object where each key-value pair corresponds to a filename.
 * @param {ElmFiles} list
 * @returns {Promise<ElmFiles | null>}
 */
const readElmFiles = async list => {
  try {
    if (list) {
      const result = [];
      for (const [key, value] of Object.entries(list)) {
        if (typeof value === 'string') {
          try {
            result.push([key, await readFile(value, 'utf-8')]);
          } catch (_) {
            throw new Error(`${value}が存在しません`);
          }
        }
      }
      return Object.fromEntries(result);
    }
    throw new Error('readFiles: 対象のelmが存在しません');
  } catch (error) {
    logError(error);
    return null;
  }
};

/**
 * Copies and modifies the 'elm.json' file to adjust source directories based on the provided 'roots'.
 * @param {string[]} roots
 * @returns {Promise<void>}
 */
const copyElmJson = async roots => {
  try {
    const elmjson = await readElmJson();
    if (elmjson) {
      const newElmJson = produce(elmjson, draft => {
        draft['source-directories'] = sourceDirectories(roots);
      });
      await writeFile(join('shiori', 'elm.json'), JSON.stringify(newElmJson, null, 2));
    }
  } catch (error) {
    logError(error);
  }
};

/**
 * Generates an array of directories for source files based on provided root directories.
 * @param {string[]} roots
 * @returns {string[]}
 */
const sourceDirectories = roots => {
  const r = roots.map(root => `../${root}`);
  return [...r, 'src'];
};

/**
 * @param {ShioriJson} shioriJson
 * @returns {Promise<string | null>}
 */
const convertShioriJson = async shioriJson => {
  try {
    if (Object.entries(shioriJson.files).length === 0)
      throw new Error('convertShioriJson: shiori.jsonのfilesが空です');
    const newJson = Object.fromEntries(
      Object.entries(shioriJson.files)
        .filter(([_, value]) => typeof value === 'string')
        .map(([_, value]) =>
          typeof value === 'string'
            ? [value, join(shioriJson.roots[0], `${toSlash(value)}.elm`)]
            : ['', '']
        )
    );
    const result = await readElmFiles(newJson);
    if (result) {
      return JSON.stringify(result);
    }
    throw new Error('convertShioriJson: resultがnullです');
  } catch (err) {
    logError(err, 'convertShioriJson');
    return null;
  }
};

/**
 * Converts all periods (.) in a given string to slashes (/).
 * @param {string} str
 * @returns {string}
 */
const toSlash = str => {
  return str.replaceAll('.', '/');
};

/**
 * Initializes the application by copying the 'shiori' directory from a base to the current working directory.
 * @returns {Promise<void>}
 */
const init = async () => {
  try {
    const p_shiori = 'shiori';
    await fse.remove(p_shiori);
    await fse.copy(join(shioriRoot(), 'boilerplate', 'shiori'), p_shiori);

    const shioriJson = await readFile(join(shioriRoot(), 'boilerplate', 'shiori.json'), 'utf-8');
    await writeFile('./shiori.json', shioriJson);

    const gitignore = await readFile(join(shioriRoot(), 'boilerplate', '.gitignore'), 'utf-8');
    await writeFile('./.gitignore', gitignore);
  } catch (err) {
    logError(err);
  }
};

/**
 * Copies the 'codegen' directory from the 'shioriRoot' directory to a specific location in 'elm-stuff'.
 * @returns {Promise<void>}
 */
const copyCodegenToElmStuff = async () => {
  try {
    const p_selmstuffCodegen = join('elm-stuff', 'shiori', 'codegen');
    await fse.remove(p_selmstuffCodegen);
    await fse.copy(join(shioriRoot(), 'codegen'), p_selmstuffCodegen);
  } catch (err) {
    logError(err);
  }
};

/**
 * Executes code generation based on the provided Shiori JSON configuration.
 * @param {ShioriJson} shioriJson
 * @returns {Promise<void>}
 */
const runCodegen = async shioriJson => {
  try {
    const flags = await convertShioriJson(shioriJson);
    if (flags) {
      process.chdir(join('elm-stuff', 'shiori'));
      await run_generation_from_cli(null, {
        output: join(process.cwd(), '..', '..', 'shiori', 'src'),
        flags: flags
      });
      process.chdir(join('..', '..'));
    }
  } catch (error) {
    logError(error);
  }
};

/**
 * Compiles the Elm source code file 'src/Shiori.elm' into a 'shiori.js' output file.
 * @returns {Promise<void>}
 */
const runElmCompile = async () => {
  try {
    process.chdir(join('shiori'));
    compile([join('src', 'Shiori.elm')], { output: join('shiori.js') });
    process.chdir('..');
  } catch (error) {
    logError(error);
  }
};

/**
 * Sets up and runs a development server environment, watches for changes in certain files.
 * @returns {Promise<void>}
 */
const serve = async () => {
  try {
    const shioriJson = await readShioriJson();
    if (shioriJson) {
      await copyCodegenToElmStuff();
      await copyElmJson(shioriJson.roots);
      await runCodegen(shioriJson);

      chokidar.watch(shioriJson.roots).on('change', async () => {
        await copyElmJson(shioriJson.roots);
        await runCodegen(shioriJson);
      });

      chokidar
        .watch(join('codegen'), {
          awaitWriteFinish: {
            stabilityThreshold: 5000,
            pollInterval: 200
          }
        })
        .on('change', async () => {
          await copyCodegenToElmStuff();
          await copyElmJson(shioriJson.roots);
          await runCodegen(shioriJson);
        });

      chokidar
        .watch(join('shiori', 'src', 'Shiori', 'Route.elm'))
        .on('change', async () => await runElmCompile());
      chokidar
        .watch(join('shiori', 'src', 'Shiori_View.elm'))
        .on('change', async () => await runElmCompile());
      chokidar
        .watch(join('shiori', 'src', 'Shiori.elm'))
        .on('change', async () => await runElmCompile());
    }
  } catch (err) {
    logError(err);
  }
};

/**
 * Logs an error message.
 * @param {unknown} error
 * @param {string} [prefix]
 */
function logError(error, prefix) {
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

const argv = yargs(hideBin(process.argv))
  .command('* [arg]', '=== commands === \n\n init \n build \n serve')
  .parseSync();

(async () => {
  const arg = argv.arg;
  if (arg === 'init') {
    await init();
  }

  if (arg === 'build') {
    try {
      const shioriJson = await readShioriJson();
      if (shioriJson) {
        await copyCodegenToElmStuff();
        await copyElmJson(shioriJson.roots);
        await runCodegen(shioriJson);
        await runElmCompile();
      }
    } catch (err) {
      logError(err);
    }
  }

  if (arg === 'serve') {
    const shioriJson = await readShioriJson();

    // WebSocket 接続クライアントの管理
    /** @type {Set<import('ws').WebSocket>} */
    const wsClients = new Set();

    chokidar.watch('shiori/shiori.js').on('change', async () => {
      for (const client of wsClients) {
        if (client.readyState === 1) {
          // OPEN
          client.send('reload');
        }
      }
    });

    chokidar
      .watch('shiori.json', { ignoreInitial: true })
      .on('add', async () => serve())
      .on('change', async () => serve());

    // Hono アプリケーションの作成
    const app = new Hono();

    app.get('/shiori.js', serveStatic({ path: './shiori/shiori.js' }));

    if (shioriJson?.assets) {
      app.use('/*', serveStatic({ root: shioriJson.assets }));
    }

    app.get('/', serveStatic({ path: './shiori/index.html' }));
    app.notFound(async c => {
      const res = await serveStatic({ path: './shiori/index.html' })(c, async () => {});
      return res || c.text('Not Found', 404);
    });

    // Hono アプリの起動
    const server = honoServe(
      {
        fetch: app.fetch,
        port: 3000
      },
      info => {
        console.log(cyan(`Running at http://localhost:${info.port}`));
      }
    );

    // WebSocket Server を Hono サーバーに統合
    // @ts-expect-error - honoServe returns ServerType which might mismatch with ws.WebSocketServer's server option.
    const wss = new WebSocketServer({ server });
    wss.on('connection', ws => {
      wsClients.add(ws);
      ws.on('close', () => {
        wsClients.delete(ws);
      });
    });

    await serve();
  }
})();
