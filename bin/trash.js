//@flow
const fs = require('fs').promises
/**
 * TODO: 使いたい
 */
const addElmExtension = (filepath /* :string */) /*:string */ => {
  return filepath.endsWith('.elm') ? filepath : filepath + '.elm'
}

/**
 * HACK: 二重否定でUndefindをfalseに変換
 */
const fileExists = async (filepath /* :string */) /*:Promise<boolean> */ => {
  try {
    return !!(await fs.lstat(filepath))
  } catch (e) {
    return false
  }
}

module.exports = {
  addElmExtension,
  fileExists
}
