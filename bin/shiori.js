#!/usr/bin/env node
// @flow
'use strict'

const fs = require('fs').promises
const { exec } = require('child_process')
const chokidar = require('chokidar')
const fse = require('fs-extra')
const path = require('path')
const yargs = require('yargs')
// $FlowFixMe
const handler = require('serve-handler')
const http = require('http')
const { bold, green, yellow, red, cyan } = require('kleur')
const { fileExists } = require('./trash.js')
const { produce } = require('immer')
const { run } = require('elm-codegen/dist/index')

/*::
type Join = '..' | 'elm-stuff' | 'codegen' | 'elm.json' | 'shiori' | 'shiori' | 'node_modules' | 'elm-codegen' | 'bin' | 'src' | 'tmp.json' | 'shiori.json' |  'elm-watch' | 'index.js' | '.' | 'node_modules/elm-shiori'
type ElmFiles = {[key:string]: string} 
type ShioriJson = {root: string,  files: ElmFiles, assets: string} 
type ElmJson = {"source-directories": string[]}
*/

const join = (...args /* :Join[] */) /*:string */ => {
  return path.join(...args)
}

const readElmJson = async () /*:Promise<ElmJson | null> */ => {
  try {
    if (await fileExists('elm.json')) {
      const json = JSON.parse(await fs.readFile('elm.json', 'utf-8'))
      if (json['source-directories']) return json
      throw new Error('elm.jsonにsource-directoriesがありません')
    }
    throw new Error('elm.jsonが存在しません')
  } catch (error) {
    console.log(red(error.toString()))
    return null
  }
}

const readShioriJson = async () /*:Promise<ShioriJson | null>*/ => {
  try {
    if (await fileExists('shiori.json')) {
      const json = JSON.parse(await fs.readFile(join('shiori.json'), 'utf-8'))
      if (json.files && json.root) return json
      throw new Error('shiori.jsonにfilesまたはrootがありません')
    }
    throw new Error('shiori.jsonが存在しません')
  } catch (error) {
    console.log(red(error.toString()))
    return null
  }
}

const readFiles = async (list /*:ElmFiles*/) /*:Promise<ElmFiles | null> */ => {
  try {
    if (list) {
      const result = []
      for (const [key, value] of Object.entries(list)) {
        if (typeof value === 'string') {
          if (await fileExists(value)) {
            result.push([key, await fs.readFile(value, 'utf-8')])
          } else {
            throw new Error(value + 'が存在しません')
          }
        }
      }
      return Object.fromEntries(result)
    }
    throw new Error('readFiles: 対象のelmが存在しません')
  } catch (error) {
    console.log(red(error))
    return null
  }
}

/* TODO: 例外処理追加 */
const copyElmJson = async (root /*:string */) /*:Promise<void> */ => {
  try {
    const elmjson = await readElmJson()
    if (elmjson) {
      const newElmJson = produce(elmjson, (draft) => {
        draft['source-directories'] = ['src', '../' + root]
      })
      await fs.writeFile(join('shiori', 'elm.json'), JSON.stringify(newElmJson))
    }
  } catch (err) {
    console.log(red(err.toString()))
  }
}

/* TODO: 例外処理追加 */
/* TODO: 命名変更 */
const configToTmp = async (shioriJson /*:ShioriJson */) /*:Promise<void> */ => {
  try {
    const newJson /*:ElmFiles */ = Object.fromEntries(
      Object.entries(shioriJson.files)
        .filter(([_, value]) => typeof value === 'string')
        .map(([_, value]) => (typeof value === 'string' ? [value, shioriJson.root + '/' + value + '.elm'] : ['', '']))
    )
    const result = await readFiles(newJson)
    if (result) {
      if (!(await fileExists(join('elm-stuff', 'shiori')))) await fs.mkdir(join('elm-stuff', 'shiori'))
      await fs.writeFile(join('elm-stuff', 'shiori', 'tmp.json'), JSON.stringify(result))
    }
  } catch (err) {
    console.log(red('configToTmp:' + err.toString()))
  }
}

/**
 * TODO: 本当にOK?みたいな確認欲しい
 * TODO: shiori.jsonのコピー処理追加
 * TODO: gitignoreのコピー処理追加
 */
/* TODO: 例外処理追加 */
const init = async () /*:Promise<void> */ => {
  try {
    const p_shiori = 'shiori'
    await fse.remove(p_shiori)
    if (!(await fileExists(p_shiori))) await fse.copy(join(shioriRoot(), 'shiori'), p_shiori)
    if (!(await fileExists(join(p_shiori, 'shiori.json'))))
      await fse.copy(join(shioriRoot(), 'shiori', 'shiori.json'), join(p_shiori, 'shiori.json'))
    throw new Error('init: すでに存在するshioriフォルダの削除に失敗しています')
  } catch (err) {
    console.log(red(err.toString()))
  }
}

const copyAssets = async (path /*:string */) /*:Promise<void> */ => {
  try {
    if (path) {
      if (await fileExists(path)) {
        const obj = produce({ path, name: '', p_assets: '' }, (draft) => {
          draft.name = draft.path.split('/').pop()
          draft.p_assets = 'shiori/' + draft.name
        })
        if (obj.name) {
          await fse.remove(obj.p_assets)
          if (!(await fileExists(obj.p_assets))) await fse.copy(path, obj.p_assets)
        }
      } else {
        throw new Error('copyAssets:' + path + 'が存在しません')
      }
    } else {
      console.log(yellow('assetsを設定していません'))
    }
  } catch (err) {
    console.log(red(err.toString()))
  }
}

/* TODO: 例外処理追加 */
const copyCodeGen = async () /*:Promise<void> */ => {
  try {
    const p_selmstuffCodegen = join('elm-stuff', 'shiori', 'codegen')
    await fse.remove(p_selmstuffCodegen)
    if (!(await fileExists(p_selmstuffCodegen))) {
      await fse.copy(join(shioriRoot(), 'codegen'), p_selmstuffCodegen)
    } else {
      throw new Error('copyCodeGen: codegenフォルダの削除に失敗しています')
    }
  } catch (err) {
    console.log(err.toString())
  }
}

/**
 * TODO: 多分execやめれた
 */
const codegen = async () /*:Promise<void> */ => {
  try {
    if (await fileExists(join('node_modules', 'elm-codegen', 'bin', 'elm-codegen'))) {
      process.chdir('elm-stuff/shiori/')
      //TODO: これならreadFileしなくても使えそうやなぁ〜って感じる
      const flags = await fs.readFile(join('tmp.json'), 'utf-8')
      run('./codegen/Generate.elm', {
        output: 'shiori/src',
        flags: JSON.parse(flags)
      })
      process.chdir('../../')
    } else {
      throw new Error('codegen: elm-codegenがインストールされていません')
    }
  } catch (error) {
    console.log(red(error.toString()))
  }
}

/**
 * TODO: execをどうにかしたい
 */
const elmWatch = async () /*:Promise<void> */ => {
  try {
    if (await fileExists(join('node_modules', 'elm-watch', 'index.js'))) {
      exec(
        `cd ${join('shiori')} && ${join('..', 'node_modules', 'elm-watch', 'index.js')} hot`,
        (err, stdout, stderr) => {
          if (err) {
            console.log(`\n===== elmWatch =====\n`, red(`${stderr}`))
            console.log(yellow(`${stdout}`))
            return
          }
          console.log(`elm-watch: ${stdout}`)
        }
      )
    } else {
      throw new Error('elmWatch: elm-watchがインストールされていません')
    }
  } catch (error) {}
}

const main = async (shioriJson /*:ShioriJson */) => {
  await copyElmJson(shioriJson.root)
  await configToTmp(shioriJson)
  await codegen()
}

const serve = async () /*:Promise<void> */ => {
  try {
    const shioriJson = await readShioriJson()
    if (shioriJson) {
      await copyAssets(shioriJson.assets)
      await copyCodeGen()
      await main(shioriJson)

      chokidar.watch(shioriJson.root).on('change', async (event, path) => {
        console.log(event, path)
        await main(shioriJson)
      })
      chokidar.watch(join('codegen')).on('change', async (event, path) => {
        console.log(event, path)
        await copyCodeGen()
        await main(shioriJson)
      })
      chokidar
        .watch(shioriJson.assets)
        .on('add', async (event, path) => await copyAssets(shioriJson.assets))
        .on('change', async (event, path) => await copyAssets(shioriJson.assets))
    }
  } catch (err) {
    console.log(red(err.toString()))
  }
}

/**
 * TODO: 表示をおしゃれにしたい
 */
const args = yargs
  .command('* arg', '=== commands === \n\n init \n build \n serve')
  .options({
    dev: {
      type: 'boolean',
      describe: '開発者用',
      demandOption: true,
      default: false
    }
  })
  .parseSync()

const shioriRoot = () /*:Join */ => (args.dev ? '.' : 'node_modules/elm-shiori')

;(async () => {
  if (args.arg === 'init') {
    await init()
  }

  if (args.arg === 'build') {
    try {
      const shioriJson = await readShioriJson()
      if (shioriJson) {
        await copyAssets(shioriJson.assets)
        await copyCodeGen()
        await main(shioriJson)
      }
    } catch (err) {
      console.log(red(err.toString()))
    }
  }

  if (args.arg === 'serve') {
    chokidar
      .watch('shiori.json')
      .on('add', async (event, path) => serve())
      .on('change', async (event, path) => serve())
    await elmWatch()

    const server = http.createServer((request, response) => {
      return handler(request, response, {
        public: join('shiori'),
        rewrites: [{ source: '**', destination: '/index.html' }]
      })
    })

    server.listen(3000, () => {
      console.log(cyan('\n Running at http://localhost:3000 \n'))
    })
  }
})()
