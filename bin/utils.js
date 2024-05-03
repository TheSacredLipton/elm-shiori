/**
 * @example
 * ```js @import.meta.vitest
 * expect(sourceDirectories([])).toStrictEqual(["src"]);
 * expect(sourceDirectories(["src", ".elm-land"])).toStrictEqual(["../src", "../.elm-land", "src"]);
 * ```
 * Generates an array of directories for source files based on provided root directories.
 * Adds a 'src' directory to the end of the array as a default source directory.
 * @param {string[]} roots - An array of root directories.
 * @returns {string[]} An array of directories, prefixed with '../', and ending with 'src'.
 */
export const sourceDirectories = roots => {
  const r = roots.map(root => `../${root}`);
  return [...r, 'src'];
};
