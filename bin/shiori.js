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
 * Builds the Shiori.Route module source code.
 * @param {ModulesMetadata} modules
 * @param {ShioriJson} [shioriJson]
 * @returns {string}
 */
const buildRouteElm = (modules, shioriJson) => {
  const moduleNames = Object.keys(modules).sort();

  const importsSection = moduleNames.map(m => `import ${m}`).join('\n');

  // 重複を排除したカスタムインポート
  const customImports = new Set();
  if (shioriJson && Array.isArray(shioriJson.imports)) {
    for (const imp of shioriJson.imports) {
      customImports.add(`import ${imp}`);
    }
  }
  for (const m of moduleNames) {
    for (const f of Object.keys(modules[m])) {
      for (const imp of modules[m][f].imports) {
        customImports.add(imp);
      }
    }
  }
  const customImportsSection = Array.from(customImports).sort().join('\n');

  // Route型定義
  const routeVariants = ['NotFound'];
  for (const m of moduleNames) {
    const variant = m.replace(/\./g, '_');
    routeVariants.push(`${variant} String (Maybe Int)`);
  }
  const routeTypeSection = `type Route\n    = ${routeVariants.join('\n    | ')}`;

  // routeParser
  const parserItems = [];
  for (const m of moduleNames) {
    const variant = m.replace(/\./g, '_');
    parserItems.push(
      `Url.Parser.map (\\f idx -> ${variant} f (Just idx)) (s "${m}" </> string </> Url.Parser.int)`
    );
    parserItems.push(`Url.Parser.map (\\f -> ${variant} f Nothing) (s "${m}" </> string)`);
  }
  const parserSection = `routeParser : Parser (Route -> b) b
routeParser =
    oneOf
        [ ${parserItems.join('\n        , ')}
        ]`;

  // view
  const viewBranches = [];
  viewBranches.push('        NotFound ->\n            []');

  for (const m of moduleNames) {
    const variant = m.replace(/\./g, '_');
    const funcBranches = [];
    for (const f of Object.keys(modules[m])) {
      const codes = modules[m][f].codes; // Array of { name, code }

      const indentCode = (/** @type {string} */ code, /** @type {number} */ spaces) => {
        const lines = code.split('\n');
        const pad = ' '.repeat(spaces);
        if (lines.length <= 1) return pad + code;
        let minIndent = Number.POSITIVE_INFINITY;
        for (const line of lines) {
          if (line.trim() === '') continue;
          const match = line.match(/^[ \t]*/);
          const indentLength = match ? match[0].length : 0;
          if (indentLength < minIndent) {
            minIndent = indentLength;
          }
        }
        if (minIndent === Number.POSITIVE_INFINITY) minIndent = 0;
        return lines
          .map((/** @type {string} */ line) => {
            const stripped = line.slice(minIndent);
            return stripped.trim() === '' ? '' : pad + stripped;
          })
          .join('\n');
      };

      const letBindings = codes
        .map((c, i) => {
          const indented = indentCode(c.code, 28);
          return `                        preview_${i} =\n${indented}`;
        })
        .join('\n\n');

      const cardCodes = codes.map((c, i) => {
        const displayName = c.name || `Preview ${i}`;
        return `Shiori_View.card "${displayName}" preview_${i}`;
      });
      const cardsJoined = cardCodes.join('\n                            , ');

      const soloBranches = codes
        .map((c, i) => {
          return `                                ${i} ->\n                                    [ Shiori_View.solo preview_${i} ] |> Shiori_View.map`;
        })
        .join('\n\n');

      funcBranches.push(
        `                "${f}" ->
                    let
${letBindings}
                    in
                    case maybeIdx of
                        Just idx ->
                            case idx of
${soloBranches}

                                _ ->
                                    []
                        Nothing ->
                            [ ${cardsJoined}
                            ] |> Shiori_View.map`
      );
    }

    viewBranches.push(`        ${variant} str maybeIdx ->
            case str of
${funcBranches.join('\n')}
                _ ->
                    []`);
  }

  const viewSection = `view : Url.Url -> List (Html.Html ())
view url =
    case url |> toRoute of
${viewBranches.join('\n\n')}`;

  // links
  const linksItems = [];
  for (const m of moduleNames) {
    const funcItems = [];
    for (const f of Object.keys(modules[m])) {
      const codes = modules[m][f].codes;
      const subItems = codes.map((c, i) => {
        const displayName = c.name || `Preview ${i}`;
        const path = `/${m}/${f}/${i}`;
        return `( "${displayName}", "${path}" )`;
      });
      funcItems.push(`( "${f}", [ ${subItems.join(', ')} ] )`);
    }
    linksItems.push(`( "${m}", [ ${funcItems.join('\n      , ')} ] )`);
  }

  const linksSection = `links : List ( String, List ( String, List ( String, String ) ) )
links =
    [ ${linksItems.join('\n    , ')}
    ]`;

  return `module Shiori.Route exposing (Route(..), links, routeParser, toRoute, view)

import Html exposing (Html)
import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, string)
import Shiori_View

${importsSection}

${customImportsSection}

${routeTypeSection}

${parserSection}

toRoute : Url.Url -> Route
toRoute url =
    url
        |> parse routeParser
        |> Maybe.withDefault NotFound

${viewSection}

${linksSection}
`;
};

/**
 * Executes code generation by running elm-review to extract metadata
 * and generating Route.elm dynamically.
 * @param {ShioriJson} shioriJson
 * @returns {Promise<void>}
 */
const runCodegen = async shioriJson => {
  try {
    const configPath = join(shioriRoot(), 'core', 'review');
    let stdout = '';
    try {
      const result = await execAsync(`npx elm-review --config ${configPath} --report json`);
      stdout = result.stdout;
    } catch (err) {
      stdout = /** @type {*} */ (err).stdout || '';
    }

    if (!stdout.trim()) {
      throw new Error('elm-review の出力が空です');
    }

    const data = JSON.parse(stdout);
    /** @type {ModulesMetadata} */
    const modules = {};

    const errors = data.errors || [];
    for (const fileError of errors) {
      const filePath = fileError.path;
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
                (/** @type {{name: string, code: string}} */ c) => {
                  const code = c.code;
                  const escapedFuncName = funcName.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
                  const regex = new RegExp(
                    `"[^"\\\\\\n]*(?:\\\\.[^"\\\\\\n]*)*"|'[^'\\\\\\n]*(?:\\\\.[^'\\\\\\n]*)*'|(?<!\\.)\\b${escapedFuncName}\\b|(?<!\\.)\\b[A-Z][a-zA-Z0-9_]*\\b(?!\\.)`,
                    'g'
                  );
                  const resolved = code.replace(regex, (/** @type {string} */ m) => {
                    if (m.startsWith('"') || m.startsWith("'")) {
                      return m;
                    }
                    if (ELM_BUILTINS.has(m)) {
                      return m;
                    }
                    if (m === funcName) {
                      return `${moduleName}.${funcName}`;
                    }
                    return `${moduleName}.${m}`;
                  });
                  return { name: c.name, code: resolved };
                }
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

    const routeElmContent = buildRouteElm(modules, shioriJson);
    const routeElmPath = join('elm-stuff', 'shiori', 'src', 'Shiori', 'Route.elm');
    await fse.ensureDir(join('elm-stuff', 'shiori', 'src', 'Shiori'));
    await writeFile(routeElmPath, routeElmContent);
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
  try {
    process.chdir(join('elm-stuff', 'shiori'));
    compile([join('src', 'Shiori.elm')], { output: join('shiori.js') });
    process.chdir(join('..', '..'));
  } catch (error) {
    logError(error);
  }
};

const serve = async () => {
  try {
    const shioriJson = await readShioriJson();
    if (shioriJson) {
      await copyElmJson(shioriJson.roots);
      await runCodegen(shioriJson);

      chokidar.watch(shioriJson.roots).on('change', async () => {
        await copyElmJson(shioriJson.roots);
        await runCodegen(shioriJson);
      });

      chokidar
        .watch(join('elm-stuff', 'shiori', 'src', 'Shiori', 'Route.elm'))
        .on('change', async () => await runElmCompile());
      chokidar
        .watch(join('elm-stuff', 'shiori', 'src', 'Shiori_View.elm'))
        .on('change', async () => await runElmCompile());
      chokidar
        .watch(join('elm-stuff', 'shiori', 'src', 'Shiori.elm'))
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
        await prepareWorkDir();
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

    await prepareWorkDir();
    await serve();
  }
})();
