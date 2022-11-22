#!/usr/bin/env node
// @ts-check
'use strict'

const fs = require('fs').promises
const { exec } = require('child_process')
const chokidar = require('chokidar')
const fse = require('fs-extra')
const path = require('path')
const yargs = require('yargs')
const handler = require('serve-handler')
const http = require('http')

const args = yargs
  .command('* arg', 'arg')
  .options({
    watch: {
      type: 'boolean',
      describe: 'watch',
      demandOption: true,
      default: false
    },
    serve: {
      type: 'boolean',
      describe: 'serve',
      demandOption: true,
      default: false
    },
    dev: {
      type: 'boolean',
      describe: '開発者用',
      demandOption: true,
      default: false
    }
  })
  .parseSync()

/** @typedef {'..' | 'elm-stuff' | 'codegen' | 'elm.json' | 'shiori' | 'shiori' | 'node_modules' | 'elm-codegen' | 'bin' | 'src' | 'tmp.json' | 'shiori.json' |  'elm-watch' | 'index.js' | '.' | 'node_modules/shiori' | 'boilerplate'} Join */

/**
 * @param {Join[]} args
 */
const join = (...args) => {
  return path.join(...args)
}

/** @typedef {{[key:string]: string}} Tests */
/** @typedef {{root: string, lib: boolean, tests: Tests[], import: string[]}} UIJson */
/** @typedef {{"source-directories" : string[]}} ElmJson */

/**
 * @returns {Join}
 */
const shioriRoot = () => (args.dev ? '.' : 'node_modules/shiori')

/**
 * @returns {Promise<ElmJson>}
 */
const readElmJson = async () => {
  return JSON.parse(await fs.readFile('elm.json', 'utf-8'))
}

/**
 * @returns {Promise<UIJson>}
 */
const readUiJson = async () => {
  return JSON.parse(await fs.readFile(join('shiori', 'shiori.json'), 'utf-8'))
}

/**
 * @param {Tests} list
 * @returns {Promise<Tests>}
 */
const readFiles = async (list) => {
  const result = []
  for (const [key, value] of Object.entries(list)) {
    result.push([key, await fs.readFile(value, 'utf-8')])
  }
  return Object.fromEntries(result)
}

/**
 * @param {string} filepath
 * @returns {Promise<boolean>}
 * HACK: 二重否定でUndefindをfalseに変換
 */
const fileExists = async (filepath) => {
  try {
    return !!(await fs.lstat(filepath))
  } catch (e) {
    return false
  }
}

/**
 * @param {string} root
 * @returns {Promise<void>}
 * TODO: let使っているのちょっといや
 * TODO: rootsにして複数受け取れるようにしたい
 */
const copyElmJson = async (root) => {
  try {
    let elmjson = await readElmJson()
    elmjson['source-directories'] = ['src', '../' + root]
    await fs.writeFile(join('shiori', 'elm.json'), JSON.stringify(elmjson))
  } catch (err) {
    console.log(err.toString())
  }
}

/**
 * @param {string} filepath
 * @returns {string}
 * TODO: 使いたい
 */
const addElmExtension = (filepath) => {
  return filepath.endsWith('.elm') ? filepath : filepath + '.elm'
}

/**
 * @param {UIJson} uijson
 * @returns {Promise<void>}
 */
const configToTmp = async (uijson) => {
  try {
    const newJson = Object.fromEntries(uijson.tests.map((value) => [value, uijson.root + '/' + value + '.elm']))

    const result = { imports: uijson.import, tests: await readFiles(newJson) }
    if (!(await fileExists(join('elm-stuff', 'shiori')))) await fs.mkdir(join('elm-stuff', 'shiori'))
    await fs.writeFile(join('elm-stuff', 'shiori', 'tmp.json'), JSON.stringify(result))
  } catch (err) {
    console.log(err.toString())
  }
}

const copyBoilerplate = async () => {
  const p_shiori = join('shiori')
  try {
    if (!(await fileExists(p_shiori))) await fse.copy(join(shioriRoot(), 'boilerplate'), p_shiori)
  } catch (err) {
    console.log(err.toString())
  }
}

/**
 * @returns {Promise<void>}
 */
const copyCodeGen = async () => {
  // const shioriRoot = isDev ? '.' : join('node_modules', 'shiori')

  const p_selmstuffCodegen = join('elm-stuff', 'shiori', 'codegen')
  try {
    await fse.remove(p_selmstuffCodegen)

    if (!(await fileExists(p_selmstuffCodegen))) await fse.copy(join(shioriRoot(), 'codegen'), p_selmstuffCodegen)
  } catch (err) {
    console.log(err.toString())
  }
}

/**
 * @returns {Promise<void>}
 * TODO: なんかexec使ってるのこわいよなぁ
 */
const codegen = async () => {
  const p_elmstuff_shioritest = join('elm-stuff', 'shiori')
  const p_nodemodule_codegen = join('..', '..', 'node_modules', 'elm-codegen', 'bin', 'elm-codegen')
  const p_codegen_output = join('..', '..', 'shiori', 'src')
  exec(
    `cd ${p_elmstuff_shioritest} && ${p_nodemodule_codegen} run --output="${p_codegen_output}" --flags-from="${'tmp.json'}"`,
    (err, stdout, stderr) => {
      if (err) {
        console.log(`stderr: ${stderr}`)
        return
      }
      console.log(`stdout: ${stdout}`)
    }
  )
}

/**
 * @returns {Promise<void>}
 * TODO:
 */
const elmWatch = async () => {
  exec(`cd ${join('shiori')} && ${join('..', 'node_modules', 'elm-watch', 'index.js')} hot`, (err, stdout, stderr) => {
    if (err) {
      console.log(`stderr: ${stderr}`)
      return
    }
    console.log(`stdout: ${stdout}`)
  })
}
/**
 * @param {UIJson} uiJson
 * @returns {Promise<void>}
 */
const main = async (uiJson) => {
  await copyElmJson(uiJson.root)
  await configToTmp(uiJson)
  await codegen()
}

/*
 */
;(async () => {
  if (args.arg === 'init') {
    await copyBoilerplate()
  }

  if (args.arg === 'serve') {
    const uiJson = await readUiJson()
    await copyCodeGen()
    await main(uiJson)

    chokidar.watch(uiJson.root).on('change', async (event, path) => {
      console.log(event, path)
      await main(uiJson)
    })
    chokidar.watch(join('codegen')).on('change', async (event, path) => {
      console.log(event, path)
      await copyCodeGen()
      await main(uiJson)
    })

    await elmWatch()

    const server = http.createServer((request, response) => {
      return handler(request, response, {
        public: join('shiori'),
        rewrites: [{ source: '**', destination: '/index.html' }]
      })
    })

    server.listen(3000, () => {
      console.log('Running at http://localhost:3000')
    })
  }
})()
