#!/usr/bin/env node
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import {
  exportBuildArtifacts,
  init,
  prepareWorkDir,
  runCodegen,
  runElmCompile
} from './lib/codegen.js';
import { copyElmJson, readShioriJson } from './lib/config.js';
import { runDevServer } from './lib/server.js';
import { cyan, logError, red } from './lib/utils.js';
import { startWatchers } from './lib/watcher.js';

const argv = yargs(hideBin(process.argv))
  .scriptName('shiori')
  .usage('$0 <command> [options]')
  .command('init', 'Initialize shiori.json configuration file')
  .command('build', 'Build preview artifacts', yargs => {
    return yargs.option('output', {
      alias: 'o',
      type: 'string',
      description: 'Output directory for build artifacts'
    });
  })
  .command('serve', 'Start dev server for component previews', yargs => {
    return yargs.option('port', {
      alias: 'p',
      type: 'number',
      description: 'Port number to run serve command on',
      default: 3000
    });
  })
  .demandCommand(1, 'Please specify a command: init, build, or serve')
  .strict()
  .help()
  .parseSync();

(async () => {
  const command = argv._[0];

  if (command === 'init') {
    await init();
  }

  if (command === 'build') {
    try {
      const shioriJson = await readShioriJson();
      if (!shioriJson) {
        console.error(
          red('shiori.json が見つかりません。まず "npx shiori init" を実行して初期化してください。')
        );
        process.exit(1);
      }
      console.log(cyan('Building preview artifacts...'));
      await prepareWorkDir();
      await copyElmJson(shioriJson.roots);
      await runCodegen(shioriJson);
      await runElmCompile();

      if (argv.output) {
        // @ts-expect-error - argv.output is string | undefined
        await exportBuildArtifacts(argv.output, shioriJson);
      }
      console.log(cyan('Build completed successfully.'));
    } catch (err) {
      logError(err);
    }
  }

  if (command === 'serve') {
    const shioriJson = await readShioriJson();
    if (!shioriJson) {
      console.error(
        red('shiori.json が見つかりません。まず "npx shiori init" を実行して初期化してください。')
      );
      process.exit(1);
    }

    console.log(cyan('Starting development server...'));
    // サーバー起動前に初期ビルドを同期的に完了させる
    await prepareWorkDir();
    await copyElmJson(shioriJson.roots);
    await runCodegen(shioriJson);
    await runElmCompile();

    // @ts-expect-error - argv.port is number
    await runDevServer(shioriJson, argv.port, startWatchers);
    await startWatchers();
  }
})();
