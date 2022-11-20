#!/usr/bin/env node
'use strict'

const fs = require('fs').promises
const { exec } = require('child_process')
const chokidar = require('chokidar')
const fse = require('fs-extra')

const readFiles = async (list) => {
  const result = {}
  for (const iterator of list) {
    for (const [key, value] of Object.entries(iterator)) {
      result[key] = await fs.readFile(value, 'utf-8')
    }
  }
  return result
}

const fileExists = async (filepath) => {
  try {
    return !!(await fs.lstat(filepath))
  } catch (e) {
    return false
  }
}

const copyElmJson = async () => {
  try {
    let elmjson = JSON.parse(await fs.readFile('elm.json', 'utf-8'))
    elmjson['source-directories'] = ['src', '../src']
    await fs.writeFile('ui-tests/elm.json', JSON.stringify(elmjson))
  } catch (err) {
    console.log(err.toString())
  }
}

const tmp = async () => {
  try {
    const uiDoctestJson = JSON.parse(await fs.readFile('ui-tests/ui-doctest.json', 'utf-8'))
    const newJson = uiDoctestJson.tests.map((test) => ({
      [test]: uiDoctestJson.root + '/' + test + '.elm'
    }))
    // console.log(newJson)
    const result = { imports: uiDoctestJson.import, tests: await readFiles(newJson) }

    if (!(await fileExists('elm-stuff/ui-doctest'))) await fs.mkdir('elm-stuff/ui-doctest')
    await fs.writeFile('elm-stuff/ui-doctest/tmp.json', JSON.stringify(result))
  } catch (err) {
    console.log(err.toString())
  }
}

// elm-stuffにコピー...npmパッケージにした時どうしよう
const copyCodeGen = async (isLib) => {
  try {
    await fse.remove('elm-stuff/ui-doctest/codegen')

    if (isLib) {
      if (!(await fileExists('elm-stuff/ui-doctest/codegen')))
        await fse.copy('codegen', 'elm-stuff/ui-doctest/codegen')
    } else {
      if (!(await fileExists('elm-stuff/ui-doctest/codegen')))
        await fse.copy('../node_modules/elm-ui-doc-test/codegen', 'elm-stuff/ui-doctest/codegen')
    }
  } catch (err) {
    console.log(err.toString())
  }
}

const codegen = async () => {
  exec(
    'cd elm-stuff/ui-doctest/ && ../../node_modules/elm-codegen/bin/elm-codegen run --output="../../ui-tests/src" --flags-from="tmp.json"',
    (err, stdout, stderr) => {
      if (err) {
        console.log(`stderr: ${stderr}`)
        return
      }
      console.log(`stdout: ${stdout}`)
    }
  )
}

;(async () => {
  const uiDoctestJson = JSON.parse(await fs.readFile('ui-tests/ui-doctest.json', 'utf-8'))
  const src = uiDoctestJson.root
  await copyCodeGen(uiDoctestJson.lib)
  chokidar.watch(src).on('all', async (event, path) => {
    console.log(event, path)
    await copyElmJson()
    await tmp()
    await codegen()
  })
})()
