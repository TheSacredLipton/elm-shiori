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

/*::
import type {Maybe} from './maybe.js'
type Join = '..' | 'elm-stuff' | 'codegen' | 'elm.json' | 'shiori' | 'shiori' | 'node_modules' | 'elm-codegen' | 'bin' | 'src' | 'tmp.json' | 'shiori.json' |  'elm-watch' | 'index.js' | '.' | 'node_modules/elm-shiori'
type ElmFiles = {[key:string]: string} 
type ShioriJson = {root: string,  files: ElmFiles, assets: string} 
type ElmJson = {"source-directories": string[]}
*/

const join = (...args /* :Join[] */) => {
  return path.join(...args)
}

const readElmJson = async () /*:Promise<ElmJson> */ => {
  return JSON.parse(await fs.readFile('elm.json', 'utf-8'))
}

const readShioriJson = async () /*:Promise<ShioriJson>*/ => {
  return JSON.parse(await fs.readFile(join('shiori.json'), 'utf-8'))
}

const readFiles = async (list /*:ElmFiles*/) /*:Promise<ElmFiles> */ => {
  const result = []
  for (const [key, value] of Object.entries(list)) {
    if (typeof value === 'string') {
      result.push([key, await fs.readFile(value, 'utf-8')])
    }
  }
  return Object.fromEntries(result)
}

/**
 * TODO: let使っているのちょっといや
 * TODO: rootsにして複数受け取れるようにしたいかも
 */
const copyElmJson = async (root /*:string */) => {
  try {
    let elmjson = await readElmJson()
    elmjson['source-directories'] = ['src', '../' + root]
    await fs.writeFile(join('shiori', 'elm.json'), JSON.stringify(elmjson))
  } catch (err) {
    console.log(red(err.toString()))
  }
}

const configToTmp = async (shioriJson /*:ShioriJson */) => {
  try {
    const newJson /*:ElmFiles */ = Object.fromEntries(
      Object.entries(shioriJson.files)
        .filter(([_, value]) => typeof value === 'string')
        .map(([_, value]) => (typeof value === 'string' ? [value, shioriJson.root + '/' + value + '.elm'] : ['', '']))
    )
    const result = await readFiles(newJson)
    if (!(await fileExists(join('elm-stuff', 'shiori')))) await fs.mkdir(join('elm-stuff', 'shiori'))
    await fs.writeFile(join('elm-stuff', 'shiori', 'tmp.json'), JSON.stringify(result))
  } catch (err) {
    console.log(red('configToTmp:' + err.toString()))
  }
}

/**
 * TODO: 本当にOK?みたいな確認欲しい
 */
const init = async () /*:Promise<void> */ => {
  try {
    const p_shiori = join('shiori')
    await fse.remove(p_shiori)
    if (!(await fileExists(p_shiori))) await fse.copy(join(shioriRoot(), 'shiori'), p_shiori)
  } catch (err) {
    console.log(red(err.toString()))
  }
}

const copyAssets = async (path /*:string */) => {
  try {
    if (path) {
      const name = path.split('/').pop()
      const p_assets = 'shiori/' + name
      await fse.remove(p_assets)

      if (name) {
        if (!(await fileExists(p_assets))) await fse.copy(path, p_assets)
      }
    } else {
      console.log(yellow('assetsが存在しません'))
    }
  } catch (err) {
    console.log(red(err.toString()))
  }
}

const copyCodeGen = async () /*:Promise<void> */ => {
  try {
    const p_selmstuffCodegen = join('elm-stuff', 'shiori', 'codegen')
    await fse.remove(p_selmstuffCodegen)
    if (!(await fileExists(p_selmstuffCodegen))) await fse.copy(join(shioriRoot(), 'codegen'), p_selmstuffCodegen)
  } catch (err) {
    console.log(err.toString())
  }
}

/**
 * TODO: なんかexec使ってるのこわいよなぁ
 */
const codegen = async () /*:Promise<void> */ => {
  exec(
    `cd ${join('elm-stuff', 'shiori')} && ${join(
      '..',
      '..',
      'node_modules',
      'elm-codegen',
      'bin',
      'elm-codegen'
    )} run --output="${join('..', '..', 'shiori', 'src')}" --flags-from="${'tmp.json'}"`,
    (err, stdout, stderr) => {
      if (err) {
        console.log(red(`\n===== codegen:err ======\n ${stderr}`))
        console.log(yellow(`${stdout}`))
        return
      }
      if (stderr) {
        console.log(red(`${stderr}`))
        return
      }
      console.log(`codegen: ${stdout}`)
    }
  )
}

/**
 * TODO:
 */
const elmWatch = async () /*:Promise<void> */ => {
  exec(`cd ${join('shiori')} && ${join('..', 'node_modules', 'elm-watch', 'index.js')} hot`, (err, stdout, stderr) => {
    if (err) {
      console.log(`\n===== elmWatch =====\n`, red(`${stderr}`))
      console.log(yellow(`${stdout}`))
      return
    }
    console.log(`elm-watch: ${stdout}`)
  })
}

const main = async (shioriJson /*:ShioriJson */) => {
  await copyElmJson(shioriJson.root)
  await configToTmp(shioriJson)
  await codegen()
}

const serve = async () /*:Promise<void> */ => {
  try {
    const shioriJson = await readShioriJson()
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
      await copyAssets(shioriJson.assets)
      await copyCodeGen()
      await main(shioriJson)
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
