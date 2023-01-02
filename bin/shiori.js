#!/usr/bin/env node
// @flow
'use strict'

const fs = require('fs').promises
const fse = require('fs-extra')
const chokidar = require('chokidar')
const { join } = require('path')
const yargs = require('yargs')
// $FlowFixMe: pnpmでignore
const handler = require('serve-handler')
const http = require('http')
const { yellow, red, cyan } = require('kleur')
const { produce } = require('immer')
const { run_generation_from_cli } = require('elm-codegen/dist/run')
const { compile } = require('node-elm-compiler/dist/index')
const { WebSocketServer } = require('ws')

/*::
type ElmFiles = {[key:string]: string} 
type ShioriJson = {roots: string[],  files: ElmFiles, assets: string} 
type ElmJson = {"source-directories": string[]}
*/
const shioriRoot = () /*:string */ => join(__dirname, '..')

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

const readElmFiles = async (list /*:ElmFiles*/) /*:Promise<ElmFiles | null> */ => {
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
const convertShioriJson = async (shioriJson /*:ShioriJson */) /*:Promise<string | null> */ => {
  try {
    if (Object.entries(shioriJson.files).length === 0) throw new Error('convertShioriJson: shiori.jsonのfilesが空です')
    const newJson /*:ElmFiles */ = Object.fromEntries(
      Object.entries(shioriJson.files)
        .filter(([_, value]) => typeof value === 'string')
        .map(([_, value]) => (typeof value === 'string' ? [value, join(shioriJson.roots[0], toSlash(value) + '.elm')] : ['', '']))
    )
    const result = await readElmFiles(newJson)
    if (result) {
      return JSON.stringify(result)
    }
    throw new Error('convertShioriJson: resultがnullです')
  } catch (err) {
    console.log(red('convertShioriJson:' + err.toString()))
    return null
  }
}

const toSlash = (str /*:string*/) /*:string*/ => str.replaceAll('.', '/')

const init = async () /*:Promise<void> */ => {
  try {
    const p_shiori = 'shiori'
    await fse.remove(p_shiori)
    await fse.copy(join(shioriRoot(), 'shiori'), p_shiori)
  } catch (err) {
    console.log(red(err.toString()))
  }
}

const copyAssets = async (path /*:string */) /*:Promise<void> */ => {
  try {
    if (path) {
      const obj = produce({ path, name: '', p_assets: '' }, (draft) => {
        draft.name = draft.path.split('/').pop()
        draft.p_assets = join('shiori', draft.name)
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

const copyCodegenToElmStuff = async () /*:Promise<void> */ => {
  try {
    const p_selmstuffCodegen = join('elm-stuff', 'shiori', 'codegen')
    await fse.remove(p_selmstuffCodegen)
    await fse.copy(join(shioriRoot(), 'codegen'), p_selmstuffCodegen)
  } catch (err) {
    console.log(err.toString())
  }
}

const runCodegen = async (shioriJson /* :ShioriJson */) /*:Promise<void> */ => {
  try {
    const flags = await convertShioriJson(shioriJson)
    if (flags) {
      process.chdir(join('elm-stuff', 'shiori'))
      await run_generation_from_cli(null, { output: join(process.cwd(), '..', '..', 'shiori', 'src'), flags: flags })
      process.chdir(join('..', '..'))
    }
  } catch (error) {
    console.log(red(error.toString()))
  }
}

/**
 * TODO: HMR対応
 */
const runElmCompile = async () /*:Promise<void> */ => {
  try {
    process.chdir(join('shiori'))
    compile([join('src', 'Shiori.elm')], { output: join('shiori.js') })
    process.chdir('..')
  } catch (error) {}
}
const serve = async () /*:Promise<void> */ => {
  try {
    const shioriJson = await readShioriJson()
    if (shioriJson) {
      await copyAssets(shioriJson.assets)
      await copyCodegenToElmStuff()
      await copyElmJson(shioriJson.roots)
      await runCodegen(shioriJson)

      chokidar.watch(shioriJson.roots).on('change', async () => {
        await copyElmJson(shioriJson.roots)
        await runCodegen(shioriJson)
      })

      chokidar
        .watch(join('codegen'), {
          awaitWriteFinish: {
            stabilityThreshold: 5000,
            pollInterval: 100,
          },
        })
        .on('change', async () => {
          await copyCodegenToElmStuff()
          await copyElmJson(shioriJson.roots)
          await runCodegen(shioriJson)
        })

      chokidar
        .watch(shioriJson.assets)
        .on('add', async () => await copyAssets(shioriJson.assets))
        .on('change', async () => await copyAssets(shioriJson.assets))

      chokidar.watch('shiori/src/Shiori/Route.elm').on('change', async () => await runElmCompile())
    }
  } catch (err) {
    console.log(red(err.toString()))
  }
}

/**
 * TODO: 表示をおしゃれにしたい
 */
const args = yargs.command('* arg', '=== commands === \n\n init \n build \n serve').parseSync()

;(async () => {
  if (args.arg === 'init') {
    await init()
  }

  if (args.arg === 'build') {
    try {
      const shioriJson = await readShioriJson()
      if (shioriJson) {
        await copyAssets(shioriJson.assets)
        await copyCodegenToElmStuff()
        await copyElmJson(shioriJson.roots)
        await runCodegen(shioriJson)
        await runElmCompile()
      }
    } catch (err) {
      console.log(red(err.toString()))
    }
  }

  if (args.arg === 'serve') {
    chokidar
      .watch('shiori.json')
      .on('add', async () => serve())
      .on('change', async () => serve())

    http
      .createServer((request, response) => {
        return handler(request, response, {
          public: join('shiori'),
          rewrites: [{ source: '**', destination: '/index.html' }],
        })
      })
      .listen(3000, () => {
        console.log(cyan('\n Running at http://localhost:3000 \n'))
      })

    const wss = new WebSocketServer({ port: 3333 })
    wss.on('connection', (ws_client) => {
      chokidar.watch('shiori/shiori.js').on('change', async () => {
        ws_client.send('reload')
      })
    })
  }
})()
