#!/usr/bin/env node
import { exec } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import { serve as honoServe } from '@hono/node-server';
import { serveStatic } from '@hono/node-server/serve-static';
import chokidar from 'chokidar';
import fse from 'fs-extra';
import { Hono } from 'hono';
import { produce } from 'immer';
import kleur from 'kleur';
import compiler from 'node-elm-compiler';
import { WebSocketServer } from 'ws';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';

const execAsync = promisify(exec);

const { compile } = compiler;
const { red, cyan } = kleur;

/**
 * @typedef {Object.<string, string>} ElmFiles
 * @typedef {Object} ShioriJson
 * @property {string[]} roots
 * @property {ElmFiles} files
 * @property {string} [assets]
 * @property {string[]} [stylesheets]
 * @property {string[]} [scripts]
 * @property {string[]} [imports]
 * @typedef {Object} ElmJson
 * @property {string[]} source-directories
 */

const __dirname = fileURLToPath(new URL('.', import.meta.url));

/** @type {import('chokidar').FSWatcher[]} */
let activeWatchers = [];

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
      await writeFile(join('elm-stuff', 'shiori', 'elm.json'), JSON.stringify(newElmJson, null, 2));
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
  const r = roots.map(root => `../../${root}`);
  return [...r, 'src'];
};

/**
 * @typedef {Object} PreviewCode
 * @property {string} name
 * @property {string} code
 *
 * @typedef {Object} ModuleMetadata
 * @property {PreviewCode[]} codes
 * @property {string[]} imports
 */

/**
 * @typedef {Object.<string, Object.<string, ModuleMetadata>>} ModulesMetadata
 */

const ELM_BUILTINS = new Set([
  'True',
  'False',
  'Maybe',
  'Just',
  'Nothing',
  'Result',
  'Ok',
  'Err',
  'List',
  'Order',
  'LT',
  'EQ',
  'GT',
  'Int',
  'Float',
  'Char',
  'String',
  'Bool',
  'Never',
  'Task',
  'Cmd',
  'Sub',
  'Program'
]);

/**
 * Executes code generation by running elm-review to extract metadata
 * and generating Route.elm dynamically.
 * @param {ShioriJson} shioriJson
 * @returns {Promise<void>}
 */
const runCodegen = async shioriJson => {
  try {
    const configPath = join(shioriRoot(), 'core', 'review');
    const cwd = join('elm-stuff', 'shiori');

    // 0. コード生成前に Route.elm をプレースホルダーでリセットする（これにより常に最新のタグ情報で再生成されるようになります）
    const placeholderRoutePath = join(shioriRoot(), 'core', 'shiori', 'src', 'Shiori', 'Route.elm');
    const targetRoutePath = join('elm-stuff', 'shiori', 'src', 'Shiori', 'Route.elm');
    await fse.copy(placeholderRoutePath, targetRoutePath);

    // 1. 自動修正を適用して Route.elm を生成/更新する
    try {
      await execAsync(`npx elm-review --config ${configPath} --fix-all-without-prompt`, { cwd });
    } catch (err) {
      // 警告エラー等が残るため例外が飛びますが、修正自体は適用されるため無視します
    }

    // 2. 他モジュールのシャオリタグ情報を収集して previews.json を作成する
    let stdout = '';
    try {
      const result = await execAsync(`npx elm-review --config ${configPath} --report json`, {
        cwd
      });
      stdout = result.stdout;
    } catch (err) {
      stdout = /** @type {*} */ (err).stdout || '';
    }

    if (!stdout.trim()) {
      stdout = '{"errors":[]}';
    }

    const data = JSON.parse(stdout);
    /** @type {Object.<string, Object.<string, {codes: {name: string, code: string}[], imports: string[]}>>} */
    const modules = {};

    const errors = data.errors || [];
    for (const fileError of errors) {
      // elm-stuff/shiori 内から見た相対パス（例: "../../src/Hello.elm"）を
      // カレントディレクトリ（例: "examples/01-hello"）から見た相対パスに正規化する
      const filePath = join('elm-stuff', 'shiori', fileError.path);
      let matchedRoot = '';
      for (const root of shioriJson.roots) {
        if (filePath.startsWith(`${root}/`)) {
          matchedRoot = `${root}/`;
          break;
        }
      }
      const relPath = matchedRoot ? filePath.slice(matchedRoot.length) : filePath;
      const moduleName = relPath.replace(/\.elm$/, '').replace(/\//g, '.');

      for (const err of fileError.errors) {
        if (err.rule === 'ShioriExtractor' && err.message.startsWith('SHIORI_EXTRACT:')) {
          const jsonStr = err.message.slice('SHIORI_EXTRACT:'.length);
          try {
            const { funcName, codes: shioriCodes, imports: importLines } = JSON.parse(jsonStr);
            if (shioriCodes && shioriCodes.length > 0) {
              if (!modules[moduleName]) {
                modules[moduleName] = {};
              }
              if (!modules[moduleName][funcName]) {
                modules[moduleName][funcName] = { codes: [], imports: [] };
              }
              const resolvedCodes = shioriCodes.map(
                (/** @type {{name: string, code: string}} */ c) => ({ name: c.name, code: c.code })
              );
              modules[moduleName][funcName].codes.push(...resolvedCodes);
              modules[moduleName][funcName].imports.push(...importLines);
            }
          } catch (e) {
            logError(e, 'Failed to parse shiori extractor JSON');
          }
        }
      }
    }

    // プレビューURLリストの生成と書き出し
    const previewUrls = [];
    for (const m of Object.keys(modules).sort()) {
      for (const f of Object.keys(modules[m])) {
        const codes = modules[m][f].codes;
        for (let i = 0; i < codes.length; i++) {
          previewUrls.push(`/preview/${m}/${f}/${i}`);
        }
      }
    }
    const previewsJsonPath = join('elm-stuff', 'shiori', 'shiori-previews.json');
    await writeFile(previewsJsonPath, JSON.stringify(previewUrls, null, 2));
  } catch (error) {
    logError(error);
  }
};

/**
 * Prepares the work directory in 'elm-stuff/shiori' by copying base template files.
 * @returns {Promise<void>}
 */
const prepareWorkDir = async () => {
  try {
    const workDir = join('elm-stuff', 'shiori');
    await fse.ensureDir(workDir);
    await fse.copy(join(shioriRoot(), 'core', 'shiori', 'src'), join(workDir, 'src'));
    await fse.copy(join(shioriRoot(), 'core', 'shiori', 'logo.svg'), join(workDir, 'logo.svg'));

    let html = await readFile(join(shioriRoot(), 'core', 'shiori', 'index.html'), 'utf-8');

    const shioriJson = await readShioriJson();
    if (shioriJson) {
      let customTags = '';
      if (Array.isArray(shioriJson.stylesheets)) {
        for (const cssPath of shioriJson.stylesheets) {
          customTags += `    <link rel="stylesheet" href="${cssPath}">\n`;
        }
      }
      if (Array.isArray(shioriJson.scripts)) {
        for (const jsPath of shioriJson.scripts) {
          customTags += `    <script src="${jsPath}"></script>\n`;
        }
      }
      if (customTags) {
        html = html.replace('</head>', `${customTags}</head>`);
      }
    }

    await writeFile(join(workDir, 'index.html'), html);
  } catch (err) {
    logError(err);
  }
};

/**
 * Initializes the application by copying the 'shiori.json' file to the current working directory.
 * @returns {Promise<void>}
 */
const init = async () => {
  try {
    const shioriJson = await readFile(join(shioriRoot(), 'core', 'shiori.json'), 'utf-8');
    await writeFile('./shiori.json', shioriJson);
  } catch (err) {
    logError(err);
  }
};

/**
 * Compiles the Elm source code file 'src/Shiori.elm' into a 'shiori.js' output file.
 * @returns {Promise<void>}
 */
const runElmCompile = async () => {
  const originalCwd = process.cwd();
  try {
    process.chdir(join('elm-stuff', 'shiori'));
    compile([join('src', 'Shiori.elm')], { output: join('shiori.js') });
  } catch (error) {
    logError(error);
  } finally {
    process.chdir(originalCwd);
  }
};

const serve = async () => {
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

/**
 * Exports build artifacts to the specified output directory.
 * @param {string} outputDir
 * @param {ShioriJson} shioriJson
 * @returns {Promise<void>}
 */
async function exportBuildArtifacts(outputDir, shioriJson) {
  try {
    const workDir = join('elm-stuff', 'shiori');
    await fse.ensureDir(outputDir);

    await fse.copy(join(workDir, 'index.html'), join(outputDir, 'index.html'));
    await fse.copy(join(workDir, 'shiori.js'), join(outputDir, 'shiori.js'));
    await fse.copy(join(workDir, 'logo.svg'), join(outputDir, 'logo.svg'));

    const previewsJsonPath = join(workDir, 'shiori-previews.json');
    if (await fse.pathExists(previewsJsonPath)) {
      await fse.copy(previewsJsonPath, join(outputDir, 'shiori-previews.json'));
    }

    if (shioriJson.assets) {
      await fse.copy(shioriJson.assets, join(outputDir, shioriJson.assets));
    }
  } catch (err) {
    logError(err, 'Failed to export artifacts');
  }
}

const argv = yargs(hideBin(process.argv))
  .command('* [arg]', '=== commands === \n\n init \n build \n serve')
  .option('output', {
    alias: 'o',
    type: 'string',
    description: 'Output directory for build artifacts'
  })
  .option('port', {
    alias: 'p',
    type: 'number',
    description: 'Port number to run serve command on',
    default: 3000
  })
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
        await prepareWorkDir();
        await copyElmJson(shioriJson.roots);
        await runCodegen(shioriJson);
        await runElmCompile();

        if (argv.output) {
          await exportBuildArtifacts(argv.output, shioriJson);
        }
      }
    } catch (err) {
      logError(err);
    }
  }

  if (arg === 'serve') {
    const shioriJson = await readShioriJson();

    // サーバー起動前に初期ビルドを同期的に完了させる
    await prepareWorkDir();
    if (shioriJson) {
      await copyElmJson(shioriJson.roots);
      await runCodegen(shioriJson);
      await runElmCompile();
    }

    // WebSocket 接続クライアントの管理
    /** @type {Set<import('ws').WebSocket>} */
    const wsClients = new Set();

    chokidar.watch('elm-stuff/shiori/shiori.js').on('change', async () => {
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

    app.get('/shiori.js', serveStatic({ path: './elm-stuff/shiori/shiori.js' }));
    app.get('/shiori-logo.svg', serveStatic({ path: './elm-stuff/shiori/logo.svg' }));

    if (shioriJson?.assets) {
      app.get('/*', async (c, next) => {
        if (
          c.req.path === '/shiori.js' ||
          c.req.path === '/shiori-logo.svg' ||
          c.req.path === '/'
        ) {
          return next();
        }
        return serveStatic({ root: shioriJson.assets })(c, next);
      });
    }

    app.get('/', serveStatic({ path: './elm-stuff/shiori/index.html' }));
    app.notFound(async c => {
      const res = await serveStatic({ path: './elm-stuff/shiori/index.html' })(c, async () => {});
      return res || c.text('Not Found', 404);
    });

    // Hono アプリの起動
    const server = honoServe(
      {
        fetch: app.fetch,
        port: argv.port
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
