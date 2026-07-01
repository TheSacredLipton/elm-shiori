# elm-shiori

## About

- 自作カードゲームのUI確認モチベで作っています
- storybook + doctest的なツール
- elmのPATH通す必要あり
- 使い方の雰囲気は[examples(作りかけ)](./examples)

## インストール

```sh
npm i -D elm-shiori
npx shiori init
```

## 使い方

1. 初回は `npx shiori init` を実行します。

2. `shiori.json` を設定します（必要に応じて、`"type": "elm-ui"` や `"type": "elm-css"` を指定できます）。

- [elm-uiの例](./examples/03-elm-ui/shiori.json)
- [elm-cssの例](./examples/04-elm-css/shiori.json)

3. Elmコードに [コメントを追加](#コメントの書き方) します。

4. `npx shiori serve` を実行します。

- <http://localhost:3000>

5. `shiori/src/Shiori.elm` を編集し、外観を変更します（不要ならスキップして構いません）。

## コメントの書き方

単体

```elm
{-|

    <shiori> button </shiori>

-}
button : Html Msg
button =
    div []
        [ Html.button [ onClick Sample ] [ text "button" ]
        ]
```

引数有りの場合

```elm
{-|

    <shiori> button "World" </shiori>

-}
button : String -> Html Msg
button str =
    div []
        [ Html.button [ onClick Sample ] [ text <| "Hello " ++ str ]
        ]
```

複数

```elm
{-|

    <shiori> button "World" </shiori>

    <shiori> button "World2" </shiori>

-}
button : String -> Html Msg
button str =
    div []
        [ Html.button [ onClick Sample ] [ text <| "Hello " ++ str ]
        ]
```

import

```elm
{-|

    import Html exposing (div)

    <shiori> div [] <| .body <| view { world = "world" } </shiori>

-}
view : Model -> { title : String, body : List (Html Msg) }
view model =
    { title = "home"
    , body = [ text <| "hello " ++ model.world ]
    }

```

複数行

対応しています。`</shiori>` を閉じタグとして配置することで、複数行にわたる Elm コードを記述できます。

```elm
{-|

    <shiori>
    div []
        [ text "Hello"
        , text "World"
        ]
    </shiori>

-}
```

## CLI

```sh
npx shiori init
npx shiori build [--output <dir>]
npx shiori serve [--port <port>]
```

* `--output`, `-o`: ビルド成果物（HTML、JS、ロゴ、アセット、プレビューURL一覧など）を指定したディレクトリへ一括でエクスポートします。
* `--port`, `-p`: 開発サーバーを起動するポート番号を指定します（デフォルト: `3000`）。

## VRT (Visual Regression Testing)

`shiori` は各コンポーネントを外枠UI（ヘッダーやサイドバー）なしで描画する **Solo表示モード** をサポートしており、VRT（ビジュアル画像比較テスト）を非常に簡単に統合できます。

### 1. Solo表示URL
`/preview/ModuleName/functionName/index`（例: `/preview/Hello/buttons/0`）に直接アクセスすると、コンポーネント単体が画面いっぱいに描画されます。VRT撮影の際はこのURLを利用することで、Shiori自身のUI変更によるテストの誤検知を防げます。

### 2. プレビューURL一覧の取得
`shiori build`（または `serve`）実行時、生成されたプレビュー用の全Solo表示URLが配列として `shiori-previews.json` に書き出されます。

```json
[
  "/preview/Hello/alertBoxes/0",
  "/preview/Hello/alertBoxes/1",
  "/preview/Hello/buttons/0"
]
```

### 3. Playwright による自動VRTテストの記述例
まず `npx shiori build --output shiori-dist` などで書き出しを行い、その出力先にある `shiori-previews.json` を動的に読み込むことで、プレビューが新規追加されてもテストコードを変更することなく、自動でVRT対象に含めることができます。

```js
import { test, expect } from '@playwright/test';
import { readFileSync } from 'node:fs';

const previews = JSON.parse(readFileSync('./shiori-dist/shiori-previews.json', 'utf-8'));

test.describe('Shiori VRT', () => {
  for (const path of previews) {
    test(`Snapshot for ${path}`, async ({ page }) => {
      await page.goto(`http://localhost:3000${path}`);
      
      // Elmの初期化と初期レンダリング完了を待つ
      await page.waitForSelector('body > div');
      
      await expect(page).toHaveScreenshot(`${path.replace(/\//g, '_')}.png`, {
        fullPage: true
      });
    });
  }
});
```

## 開発

- Global install推奨
  - node
  - elm

```sh
git clone https://github.com/TheSacredLipton/elm-shiori.git
npm start 01-hello
```

確認

```sh
npm i -D git+https://github.com/TheSacredLipton/elm-shiori.git#branch-name
npx shiori init
```

### npm publish

- とりあえず手動

```sh
npm run npm-publish
```

## ライセンス

- MIT license

