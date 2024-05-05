# elm-shiori

- 自作カードゲームのUI確認モチベで作っています
- storybook + doctest的なツール
- elmのPATH通す必要あり
- 現状bunの利用必須、クロスコンパイルは気が向いたら
- bunあまりよくわかってない
- 使い方の雰囲気は[examples](./examples)
- macでしか動作確認していない

## インストール

bun(推奨)

```sh
bun add -D elm-shiori
bun -b shiori init
```

npm(未検証)

```sh
npm i -D bun elm-shiori
npx bun -b shiori init
```

pnpm(ちょっとだけ試した)

```sh
pnpm i -D bun elm-shiori
pnpm bun -b shiori init
```

## 使い方


1.初回は`bun -b shiori init`を実行

2.【Optional】`shiori/Shiori_View.elm`を編集

- [elm-uiの例](https://github.com/TheSacredLipton/elm-shiori/blob/main/examples/03-elm-ui/shiori/src/Shiori_View.elm)

3.【Optional】`shiori/index.html`を編集し任意のCSSやjs等読み込ませる

4.[examples](./examples)を参考に`shiori.json`を設定

5.[コメント追加](#コメントの書き方)

6.`bun -b shiori serve`

- <http://localhost:3000>
- 気が向いたらport変更できるようにする予定

## コメントの書き方

単体

```elm
{-|

    <shiori> button

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

    <shiori> button "World"

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

    <shiori> button "World"

    <shiori> button "World2"

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

    <shiori> div [] <| .body <| view { world = "world" }

-}
view : Model -> { title : String, body : List (Html Msg) }
view model =
    { title = "home"
    , body = [ text <| "hello " ++ model.world ]
    }

```

複数行

- 現状**非対応**です。1行で書き切ってください。
- 気が向いたら対応します。

## CLI

```sh
bun -b shiori init
bun -b shiori build
bun -b shiori serve
```

## 開発

- global install必要
    - bun
    - elm

### 基本

```sh
cd examples/【n-任意】
bun --watch ../../bin/shiori.ts serve
```

### 検証

```sh
bun add -D https://github.com/TheSacredLipton/elm-shiori.git#branch-name
bun -b shiori init
```

あるいは[インストール](#インストール)参照

### npm publish

- とりあえず手動
- 気が向いたらgithub actions

```sh
bun npm-publish
```

## ライセンス

- MIT license
- 一部[elm-codegen](https://github.com/mdgriffith/elm-codegen)で生成されたコードを含みます
