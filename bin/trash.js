//@flow

/**
 * TODO: 使いたい
 */
const addElmExtension = (filepath /* :string */) /*:string */ => {
  return filepath.endsWith('.elm') ? filepath : filepath + '.elm'
}

module.exports = {
  addElmExtension
}
