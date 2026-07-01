import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { produce } from 'immer';
import { logError, red, shioriRoot } from './utils.js';

/**
 * @typedef {Object} ShioriJson
 * @property {string[]} roots
 * @property {string} [assets]
 * @property {string[]} [stylesheets]
 * @property {string[]} [scripts]
 * @property {string[]} [imports]
 * @property {'html' | 'elm-ui' | 'elm-css'} [type]
 * @typedef {Object} ElmJson
 * @property {string[]} source-directories
 */

/**
 * Validates the structure and types of the shiori.json configuration object.
 * @param {any} json
 * @throws {Error} If validation fails.
 */
export const validateShioriJson = json => {
  if (!json || typeof json !== 'object' || Array.isArray(json)) {
    throw new Error('shiori.json の形式が正しくありません (オブジェクトである必要があります)。');
  }
  if (!json.roots || !Array.isArray(json.roots)) {
    throw new Error('shiori.json に必須項目 "roots" 配列がありません。');
  }
  for (const root of json.roots) {
    if (typeof root !== 'string') {
      throw new Error('shiori.json の "roots" 配列の要素はすべて文字列である必要があります。');
    }
  }
  if (json.assets !== undefined && typeof json.assets !== 'string') {
    throw new Error('shiori.json の "assets" は文字列である必要があります。');
  }
  /** @param {string} field */
  const checkStringArray = field => {
    if (json[field] !== undefined) {
      if (!Array.isArray(json[field])) {
        throw new Error(`shiori.json の "${field}" は配列である必要があります。`);
      }
      for (const item of json[field]) {
        if (typeof item !== 'string') {
          throw new Error(
            `shiori.json の "${field}" 配列の要素はすべて文字列である必要があります。`
          );
        }
      }
    }
  };
  checkStringArray('stylesheets');
  checkStringArray('scripts');
  checkStringArray('imports');
  if (json.type !== undefined && !['html', 'elm-ui', 'elm-css'].includes(json.type)) {
    throw new Error(
      'shiori.json の "type" は "html"、"elm-ui"、"elm-css" のいずれかである必要があります。'
    );
  }
};

/**
 * Reads and parses the 'elm.json' file, checking for the 'source-directories' property.
 * @returns {Promise<ElmJson | null>}
 */
export const readElmJson = async () => {
  try {
    const content = await readFile('elm.json', 'utf-8');
    const json = JSON.parse(content);
    if (!json['source-directories']) {
      throw new Error('elm.json に source-directories がありません');
    }
    return json;
  } catch (error) {
    logError(error);
    return null;
  }
};

/**
 * Reads and parses the 'shiori.json' file, validating its properties.
 * Exits the process if the file is invalid JSON or fails validation.
 * @returns {Promise<ShioriJson | null>}
 */
export const readShioriJson = async () => {
  let content;
  try {
    content = await readFile('shiori.json', 'utf-8');
  } catch (error) {
    return null;
  }

  let json;
  try {
    json = JSON.parse(content);
  } catch (error) {
    console.error(red('shiori.json のパースに失敗しました。JSONの形式を確認してください。'));
    logError(error);
    process.exit(1);
  }

  try {
    validateShioriJson(json);
  } catch (error) {
    console.error(red('shiori.json の設定値が無効です:'));
    console.error(red(error instanceof Error ? error.message : String(error)));
    process.exit(1);
  }

  return json;
};

/**
 * Generates an array of directories for source files based on provided root directories.
 * @param {string[]} roots
 * @returns {string[]}
 */
export const sourceDirectories = roots => {
  const r = roots.map(root => `../../${root}`);
  return [...r, 'src'];
};

/**
 * Copies and modifies the 'elm.json' file to adjust source directories based on the provided 'roots'.
 * @param {string[]} roots
 * @returns {Promise<void>}
 */
export const copyElmJson = async roots => {
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
