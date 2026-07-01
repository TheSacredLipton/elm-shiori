import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import fse from 'fs-extra';
import compiler from 'node-elm-compiler';
import { readShioriJson } from './config.js';
import { cyan, execAsync, logError, shioriRoot } from './utils.js';

const { compile } = compiler;

/**
 * @typedef {import('./config.js').ShioriJson} ShioriJson
 */

/**
 * Executes code generation by running elm-review to extract metadata
 * and generating Route.elm dynamically.
 * @param {ShioriJson} shioriJson
 * @returns {Promise<void>}
 */
export const runCodegen = async shioriJson => {
  try {
    const configPath = join(shioriRoot(), 'core', 'review');
    const cwd = join('elm-stuff', 'shiori');

    // 0. コード生成前に Route.elm をプレースホルダーでリセットする（これにより常に最新のタグ情報で再生成されるようになります）
    const targetRoutePath = join('elm-stuff', 'shiori', 'src', 'Shiori', 'Route.elm');
    const placeholderContent = 'module Shiori.Route exposing (..)\n';
    await fse.ensureDir(join('elm-stuff', 'shiori', 'src', 'Shiori'));
    await writeFile(targetRoutePath, placeholderContent);

    // 1. 自動修正を適用して Route.elm を生成/更新する
    try {
      await execAsync(`npx elm-review --config ${configPath} --fix-all-without-prompt`, { cwd });
    } catch (err) {
      // 警告エラー等が残るため例外が飛びますが、修正自体は適用されるため無視します
    }

    // 2. 他モジュールのシャオリタグ情報を収集して previews.json を作成する
    let stdout = '';
    try {
      const result = await execAsync(`npx elm-review --config ${configPath} --report json`, {
        cwd
      });
      stdout = result.stdout;
    } catch (err) {
      stdout = /** @type {*} */ (err).stdout || '';
    }

    if (!stdout.trim()) {
      stdout = '{"errors":[]}';
    }

    const data = JSON.parse(stdout);
    /** @type {Object.<string, Object.<string, {codes: {name: string, code: string}[], imports: string[]}>>} */
    const modules = {};

    const errors = data.errors || [];
    for (const fileError of errors) {
      // elm-stuff/shiori 内から見た相対パス（例: "../../src/Hello.elm"）を
      // カレントディレクトリ（例: "examples/01-hello"）から見た相対パスに正規化する
      const filePath = join('elm-stuff', 'shiori', fileError.path);
      let matchedRoot = '';
      for (const root of shioriJson.roots) {
        if (filePath.startsWith(`${root}/`)) {
          matchedRoot = `${root}/`;
          break;
        }
      }
      const relPath = matchedRoot ? filePath.slice(matchedRoot.length) : filePath;
      const moduleName = relPath.replace(/\.elm$/, '').replace(/\//g, '.');

      for (const err of fileError.errors) {
        if (err.rule === 'ShioriExtractor' && err.message.startsWith('SHIORI_EXTRACT:')) {
          const jsonStr = err.message.slice('SHIORI_EXTRACT:'.length);
          try {
            const { funcName, codes: shioriCodes, imports: importLines } = JSON.parse(jsonStr);
            if (shioriCodes && shioriCodes.length > 0) {
              if (!modules[moduleName]) {
                modules[moduleName] = {};
              }
              if (!modules[moduleName][funcName]) {
                modules[moduleName][funcName] = { codes: [], imports: [] };
              }
              const resolvedCodes = shioriCodes.map(
                (/** @type {{name: string, code: string}} */ c) => ({ name: c.name, code: c.code })
              );
              modules[moduleName][funcName].codes.push(...resolvedCodes);
              modules[moduleName][funcName].imports.push(...importLines);
            }
          } catch (e) {
            logError(e, 'Failed to parse shiori extractor JSON');
          }
        }
      }
    }

    // プレビューURLリストの生成と書き出し
    const previewUrls = [];
    for (const m of Object.keys(modules).sort()) {
      for (const f of Object.keys(modules[m])) {
        const codes = modules[m][f].codes;
        for (let i = 0; i < codes.length; i++) {
          previewUrls.push(`/preview/${m}/${f}/${i}`);
        }
      }
    }
    const previewsJsonPath = join('elm-stuff', 'shiori', 'shiori-previews.json');
    await writeFile(previewsJsonPath, JSON.stringify(previewUrls, null, 2));
  } catch (error) {
    logError(error);
  }
};

/**
 * Prepares the work directory in 'elm-stuff/shiori' by copying base template files.
 * @returns {Promise<void>}
 */
export const prepareWorkDir = async () => {
  try {
    const workDir = join('elm-stuff', 'shiori');
    await fse.ensureDir(workDir);
    await fse.copy(join(shioriRoot(), 'core', 'shiori', 'src'), join(workDir, 'src'));
    await fse.copy(join(shioriRoot(), 'core', 'shiori', 'logo.svg'), join(workDir, 'logo.svg'));

    const shioriJson = await readShioriJson();

    // shioriJson.type に応じた Shiori_View.elm の生成
    const type = shioriJson?.type || 'html';
    const shioriViewPath = join(workDir, 'src', 'Shiori_View.elm');
    if (type === 'elm-ui') {
      const elmUiShioriView = `module Shiori_View exposing (card, map, solo)

import Html exposing (Html)
import Html.Attributes exposing (style)
import Element exposing (Element)

map : List (Html msg) -> List (Html ())
map =
    List.map <| Html.map (always ())

card : String -> Element msg -> Html msg
card label content =
    Element.layout
        [ Element.width Element.fill ]
        (Element.el
            [ Element.htmlAttribute (style "border" "1px solid #e7e5e4")
            , Element.htmlAttribute (style "border-radius" "12px")
            , Element.htmlAttribute (style "background-color" "#ffffff")
            , Element.htmlAttribute (style "display" "flex")
            , Element.htmlAttribute (style "flex-direction" "column")
            , Element.htmlAttribute (style "overflow" "hidden")
            , Element.htmlAttribute (style "box-shadow" "0 1px 3px 0 rgba(0, 0, 0, 0.05)")
            , Element.width Element.fill
            ]
            (Element.column [ Element.width Element.fill ]
                [ Element.el
                    [ Element.paddingXY 16 10
                    , Element.htmlAttribute (style "background-color" "#fafaf9")
                    , Element.htmlAttribute (style "border-bottom" "1px solid #e7e5e4")
                    , Element.htmlAttribute (style "font-size" "12px")
                    , Element.htmlAttribute (style "font-weight" "600")
                    , Element.htmlAttribute (style "color" "#78716c")
                    , Element.htmlAttribute (style "letter-spacing" "0.025em")
                    ]
                    (Element.text label)
                , Element.el
                    [ Element.padding 24
                    , Element.htmlAttribute (style "background-color" "#ffffff")
                    , Element.width Element.fill
                    ]
                    content
                ]
            )
        )

solo : Element msg -> Html msg
solo content =
    Element.layout [ Element.width Element.fill, Element.height Element.fill ] content
`;
      await writeFile(shioriViewPath, elmUiShioriView);
    } else if (type === 'elm-css') {
      const elmCssShioriView = `module Shiori_View exposing (card, map, solo)

import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Styled exposing (toUnstyled)

map : List (Html msg) -> List (Html ())
map =
    List.map <| Html.map (always ())

card : String -> Html.Styled.Html msg -> Html msg
card label content =
    div
        [ style "border" "1px solid #e7e5e4"
        , style "border-radius" "12px"
        , style "background-color" "#ffffff"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "overflow" "hidden"
        , style "box-shadow" "0 1px 3px 0 rgba(0, 0, 0, 0.05)"
        , style "width" "100%"
        , style "box-sizing" "border-box"
        ]
        [ div
            [ style "padding" "10px 16px"
            , style "background-color" "#fafaf9"
            , style "border-bottom" "1px solid #e7e5e4"
            , style "font-size" "12px"
            , style "font-weight" "600"
            , style "color" "#78716c"
            , style "letter-spacing" "0.025em"
            ]
            [ text label ]
        , div
            [ style "padding" "24px"
            , style "background-color" "#ffffff"
            , style "width" "100%"
            , style "box-sizing" "border-box"
            ]
            [ toUnstyled content ]
        ]

solo : Html.Styled.Html msg -> Html msg
solo content =
    div
        [ style "width" "100%"
        , style "height" "100%"
        , style "box-sizing" "border-box"
        ]
        [ toUnstyled content ]
`;
      await writeFile(shioriViewPath, elmCssShioriView);
    }

    let html = await readFile(join(shioriRoot(), 'core', 'shiori', 'index.html'), 'utf-8');

    if (shioriJson) {
      let customTags = '';
      if (Array.isArray(shioriJson.stylesheets)) {
        for (const cssPath of shioriJson.stylesheets) {
          customTags += `    <link rel="stylesheet" href="${cssPath}">\n`;
        }
      }
      if (Array.isArray(shioriJson.scripts)) {
        for (const jsPath of shioriJson.scripts) {
          customTags += `    <script src="${jsPath}"></script>\n`;
        }
      }
      if (customTags) {
        html = html.replace('</head>', `${customTags}</head>`);
      }
    }

    await writeFile(join(workDir, 'index.html'), html);
  } catch (err) {
    logError(err);
  }
};

/**
 * Initializes the application by copying the 'shiori.json' file to the current working directory.
 * @returns {Promise<void>}
 */
export const init = async () => {
  try {
    const shioriJson = await readFile(join(shioriRoot(), 'core', 'shiori.json'), 'utf-8');
    await writeFile('./shiori.json', shioriJson);
    console.log(cyan('shiori.json configuration file has been created successfully.'));
  } catch (err) {
    logError(err);
  }
};

/**
 * Compiles the Elm source code file 'src/Shiori.elm' into a 'shiori.js' output file.
 * @returns {Promise<void>}
 */
export const runElmCompile = async () => {
  const originalCwd = process.cwd();
  try {
    process.chdir(join('elm-stuff', 'shiori'));
    compile([join('src', 'Shiori.elm')], { output: join('shiori.js') });
  } catch (error) {
    logError(error);
  } finally {
    process.chdir(originalCwd);
  }
};

/**
 * Exports build artifacts to the specified output directory.
 * @param {string} outputDir
 * @param {ShioriJson} shioriJson
 * @returns {Promise<void>}
 */
export async function exportBuildArtifacts(outputDir, shioriJson) {
  try {
    const workDir = join('elm-stuff', 'shiori');
    await fse.ensureDir(outputDir);

    await fse.copy(join(workDir, 'index.html'), join(outputDir, 'index.html'));
    await fse.copy(join(workDir, 'shiori.js'), join(outputDir, 'shiori.js'));
    await fse.copy(join(workDir, 'logo.svg'), join(outputDir, 'logo.svg'));

    const previewsJsonPath = join(workDir, 'shiori-previews.json');
    if (await fse.pathExists(previewsJsonPath)) {
      await fse.copy(previewsJsonPath, join(outputDir, 'shiori-previews.json'));
    }

    if (shioriJson.assets) {
      await fse.copy(shioriJson.assets, join(outputDir, shioriJson.assets));
    }
  } catch (err) {
    logError(err, 'Failed to export artifacts');
  }
}
