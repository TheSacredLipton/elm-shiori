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
const { produce } = require('immer')
const { run_generation_from_cli } = require('elm-codegen/dist/run')

/*::
type Join = '..' | 'elm-stuff' | 'codegen' | 'elm.json' | 'shiori' | 'shiori' | 'node_modules' | 'elm-codegen' | 'bin' | 'src' | 'tmp.json' | 'shiori.json' |  'elm-watch' | 'index.js' | '.' | 'node_modules/elm-shiori'
type ElmFiles = {[key:string]: string} 
type ShioriJson = {roots: string[],  files: ElmFiles, assets: string} 
type ElmJson = {"source-directories": string[]}
*/

const join = (...args /* :Join[] */) /*:string */ => {
  return path.join(...args)
}

const readElmJson = async () /*:Promise<ElmJson | null> */ => {
  try {
    try {
      const json = JSON.parse(await fs.readFile('elm.json', 'utf-8'))
      if (json['source-directories']) return json
      throw new Error('elm.jsonにsource-directoriesがありません')
    } catch (error) {
      throw new Error(error + 'elm.jsonが存在しません')
    }
  } catch (error) {
    console.log(red(error.toString()))
    return null
  }
}

const readShioriJson = async () /*:Promise<ShioriJson | null>*/ => {
  try {
    try {
      const json = JSON.parse(await fs.readFile(join('shiori.json'), 'utf-8'))
      if (json.files && json.roots) return json
      throw new Error('shiori.jsonにfilesまたはrootがありません')
    } catch (error) {
      throw new Error(error + 'shiori.jsonが存在しません')
    }
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
          try {
            result.push([key, await fs.readFile(value, 'utf-8')])
          } catch (_) {
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
const copyElmJson = async (roots /*:string[] */) /*:Promise<void> */ => {
  try {
    const elmjson = await readElmJson()
    if (elmjson) {
      const newElmJson = produce(elmjson, (draft) => {
        draft['source-directories'] = sourceDirectories(roots)
      })
      await fs.writeFile(join('shiori', 'elm.json'), JSON.stringify(newElmJson))
    }
  } catch (err) {
    console.log(red(err.toString()))
  }
}

const sourceDirectories = (roots /*:string[] */) /*:string[] */ => {
  const r = roots.map((root) => '../' + root)
  return [...r, 'src']
}

/* FIXME: 一旦shioriJson.roots[0]にしているので先頭に設定したものしか対象にならない
分ける需要が不明なので一旦これで
*/
const configToString = async (shioriJson /*:ShioriJson */) /*:Promise<string | null> */ => {
  try {
    if (Object.entries(shioriJson.files).length === 0) throw new Error('configToString: shiori.jsonのfilesが空です')
    const newJson /*:ElmFiles */ = Object.fromEntries(
      Object.entries(shioriJson.files)
        .filter(([_, value]) => typeof value === 'string')
        .map(([_, value]) =>
          typeof value === 'string' ? [value, shioriJson.roots[0] + '/' + toSlash(value) + '.elm'] : ['', '']
        )
    )
    const result = await readFiles(newJson)
    if (result) {
      return JSON.stringify(result)
    }
    throw new Error('configToString: resultがnullです')
  } catch (err) {
    console.log(red('configToString:' + err.toString()))
    return null
  }
}

const toSlash = (str /*:string*/) /*:string*/ => str.replaceAll('.', '/')

/**
 * TODO: 本当にOK?みたいな確認欲しい
 * TODO: shiori.jsonのコピー処理追加
 * TODO: gitignoreのコピー処理追加
 */
const init = async () /*:Promise<void> */ => {
  try {
    const p_shiori = 'shiori'
    await fse.remove(p_shiori)
    await fse.copy(join(shioriRoot(), 'shiori'), p_shiori)
  } catch (err) {
    console.log(red(err.toString()))
  }
}

/* HACK: 上書きでエラー出して欲しくなかったのでCopy時のエラーを握りつぶす形式 */
const copyAssets = async (path /*:string */) /*:Promise<void> */ => {
  try {
    if (path) {
      const obj = produce({ path, name: '', p_assets: '' }, (draft) => {
        draft.name = draft.path.split('/').pop()
        draft.p_assets = 'shiori/' + draft.name
      })
      if (obj.name) {
        await fse.copy(path, obj.p_assets, (err) => {})
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
    await fse.copy(join(shioriRoot(), 'codegen'), p_selmstuffCodegen)
  } catch (err) {
    console.log(err.toString())
  }
}

/**
 * TODO: 例外処理再建等
 */
const codegen = async (shioriJson /* :ShioriJson */) /*:Promise<void> */ => {
  try {
    const flags = await configToString(shioriJson)
    if (flags) {
      process.chdir('elm-stuff/shiori/')
      await run_generation_from_cli(null, { output: 'shiori/src', flags: flags })
      process.chdir('../../')
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
  } catch (error) {}
}

const serve = async () /*:Promise<void> */ => {
  try {
    const shioriJson = await readShioriJson()
    if (shioriJson) {
      await copyAssets(shioriJson.assets)
      await copyCodeGen()
      await copyElmJson(shioriJson.roots)
      await codegen(shioriJson)

      chokidar.watch(shioriJson.roots).on('change', async (event, path) => {
        console.log(event, path)
        await copyElmJson(shioriJson.roots)
        await codegen(shioriJson)
      })
      chokidar.watch(join('codegen')).on('change', async (event, path) => {
        console.log(event, path)
        await copyCodeGen()
        await copyElmJson(shioriJson.roots)
        await codegen(shioriJson)
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
        await copyElmJson(shioriJson.roots)
        await codegen(shioriJson)
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
