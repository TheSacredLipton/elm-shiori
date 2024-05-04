#!/usr/bin/env node

import { join } from 'node:path';
import chokidar from 'chokidar';
import fse from 'fs-extra';
const yargs = require('yargs');
const { red, cyan } = require('kleur');
import path from 'node:path';
import { staticPlugin } from '@elysiajs/static';
import { run_generation_from_cli } from 'elm-codegen/dist/run';
import { Elysia } from 'elysia';
import { produce } from 'immer';
import { compile } from 'node-elm-compiler/dist/index';
type ElmFiles = { [key: string]: string };
type ShioriJson = { roots: string[]; files: ElmFiles; assets: string };
type ElmJson = { 'source-directories': string[] };

const shioriRoot = (): string => join(__dirname, '..');

/**
 * Reads and parses the 'elm.json' file, checking for the 'source-directories' property.
 */
const readElmJson = async (): Promise<ElmJson | null> => {
  try {
    try {
      const json = JSON.parse(await Bun.file('elm.json', { type: 'application/json' }).text());
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
 * @returns {Promise<ShioriJson|null>}
 */
const readShioriJson = async () => {
  try {
    try {
      const json = JSON.parse(
        await Bun.file(join('shiori.json'), { type: 'application/json' }).text()
      );
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
 */
const readElmFiles = async (list: ElmFiles): Promise<ElmFiles | null> => {
  try {
    if (list) {
      const result = [];
      for (const [key, value] of Object.entries(list)) {
        if (typeof value === 'string') {
          try {
            result.push([key, await Bun.file(value, { type: 'application/json' }).text()]);
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
 */
const copyElmJson = async (roots: string[]): Promise<void> => {
  try {
    const elmjson = await readElmJson();
    if (elmjson) {
      const newElmJson = produce(elmjson, (draft: { [x: string]: string[] }) => {
        draft['source-directories'] = sourceDirectories(roots);
      });
      await Bun.write(join('shiori', 'elm.json'), JSON.stringify(newElmJson));
    }
  } catch (error) {
    logError(error);
  }
};

/**
 * TODO: expect(sourceDirectories([])).toStrictEqual(["src"]);
 * TODO: expect(sourceDirectories(["src", ".elm-land"])).toStrictEqual(["../src", "../.elm-land", "src"]);
 * Generates an array of directories for source files based on provided root directories.
 * Adds a 'src' directory to the end of the array as a default source directory.
 */
const sourceDirectories = (roots: string[]): string[] => {
  const r = roots.map(root => `../${root}`);
  return [...r, 'src'];
};

/**
 * Converts the `ShioriJson` configuration into a JSON string representation of Elm files,
 * using only the first root directory specified in `shioriJson.roots`. This includes transforming
 * file paths into a specific format required for Elm source files.
 *
 * FIXME: Currently only the first item in `shioriJson.roots` is used. It's unclear if there's
 * a need to handle multiple directories. This implementation could potentially be adjusted in the future.
 */
const convertShioriJson = async (shioriJson: ShioriJson): Promise<string | null> => {
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
 */
const toSlash = (str: string): string => {
  return str.replaceAll('.', '/');
};

/**
 * Initializes the application by copying the 'shiori' directory from a base to the current working directory.
 * It first removes any existing 'shiori' directory and then copies the entire content from the source.
 */
const init = async (): Promise<void> => {
  try {
    const p_shiori = 'shiori';
    await fse.remove(p_shiori);
    await fse.copy(join(shioriRoot(), 'shiori'), p_shiori);
  } catch (err) {
    logError(err);
  }
};

/**
 * Copies assets from a specified directory to a target directory in 'shiori' based on the assets' names.
 * TODO: copyStaticFileとかでも良さげ
 */
const copyAssets = async (sourcePath: string): Promise<void> => {
  try {
    if (!sourcePath) {
      console.error('No source path specified for assets.');
      return;
    }

    // Extract the directory name from the input source path
    const directoryName = sourcePath.split('/').pop();

    // Ensure we have a valid directory name
    if (!directoryName) {
      throw new Error('Failed to extract a valid directory name from the source path.');
    }

    // Target path in 'shiori' directory
    const targetPath = path.join('shiori');

    // Copying the directory and its contents to the target path
    const copyOptions = {
      overwrite: true, // Overwrite files at destination if they exist
      errorOnExist: false
    };
    await fse.copy(sourcePath, targetPath, copyOptions);

    console.log(`Assets successfully copied to ${targetPath}`);
  } catch (error) {
    logError(error, 'Error copying assets');
  }
};

/**
 * Copies the 'codegen' directory from the 'shioriRoot' directory to a specific location in 'elm-stuff'.
 * This is useful for setting up the necessary code generation files in the right place.
 * @returns {Promise<void>} Resolves when the copying is complete, logs any errors that occur.
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
 * This includes setting up the directory environment and running generation commands.
 */
const runCodegen = async (shioriJson: ShioriJson): Promise<void> => {
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
 * The function changes the current working directory during the process for the compilation context.
 * or silently handles any errors that occur.
 * @todo Implement Hot Module Replacement (HMR) capabilities.
 */
const runElmCompile = async (): Promise<void> => {
  try {
    process.chdir(join('shiori'));
    compile([join('src', 'Shiori.elm')], { output: join('shiori.js') });
    process.chdir('..');
  } catch (error) {
    logError(error);
  }
};

/**
 * Sets up and runs a development server environment, watches for changes in certain files,
 * and performs automated tasks such as copying assets, running code generation, and compiling code.
 */
const serve = async (): Promise<void> => {
  try {
    const shioriJson = await readShioriJson();
    if (shioriJson) {
      await copyAssets(shioriJson.assets);
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
        .watch(shioriJson.assets)
        .on('add', async () => await copyAssets(shioriJson.assets))
        .on('change', async () => await copyAssets(shioriJson.assets));

      chokidar.watch('shiori/src/Shiori/Route.elm').on('change', async () => await runElmCompile());
    }
  } catch (err) {
    logError(err);
  }
};

/**
 * Logs an error message. If the error is an instance of Error, it logs the error's message in red.
 * Otherwise, it logs a generic unknown error message in red.
 */
function logError(error: unknown, prefix?: string): void {
  // Check if the error is an instance of Error
  if (error instanceof Error) {
    // If error is an instance of Error, safely call toString() and color it red
    if (prefix) {
      console.log(red(`${prefix}: ${error.toString()}`));
    } else {
      console.log(red(error.toString()));
    }
  } else {
    // If it's not an instance of Error, log a generic unknown error message
    console.log(red('An unknown error occurred'));
  }
}

const args = yargs.command('* arg', '=== commands === \n\n init \n build \n serve').parseSync();
(async () => {
  if (args.arg === 'init') {
    await init();
  }

  if (args.arg === 'build') {
    try {
      const shioriJson = await readShioriJson();
      if (shioriJson) {
        await copyAssets(shioriJson.assets);
        await copyCodegenToElmStuff();
        await copyElmJson(shioriJson.roots);
        await runCodegen(shioriJson);
        await runElmCompile();
      }
    } catch (err) {
      logError(err);
    }
  }

  if (args.arg === 'serve') {
    let ws: { send: (message: string) => void } | null;
    chokidar.watch('shiori/shiori.js').on('change', async () => {
      if (ws) ws.send('reload');
    });
    chokidar
      .watch('shiori.json')
      .on('add', async () => serve())
      .on('change', async () => serve());
    const serve_ = new Elysia()
      .ws('/ws', {
        open(ws_) {
          // TODO: なんか嫌
          ws = ws_;
        }
      })
      .use(staticPlugin({ assets: 'shiori' }))
      .get('/shiori.js', () => {
        return new Response(Bun.file('shiori/shiori.js'));
      })
      .get('/*', () => {
        return new Response(Bun.file('shiori/index.html'));
      })
      .listen(3000);
    serve_
      .handle(new Request('http://localhost/'))
      .then(() => console.log(cyan('Running at http://localhost:3000')));
  }
})();
