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

1.初回は`npx shiori init`を実行

2.[examples](./examples)を参考に`shiori/src/Shiori_View.elm`を編集

- [elm-uiの例](https://github.com/TheSacredLipton/elm-shiori/blob/main/examples/03-elm-ui/shiori/src/Shiori_View.elm)

3.`shiori/src/index.html`を編集し任意のCSSやjs等読み込ませる

4.[examples](./examples)を参考に`shiori.json`を設定

5.[コメント追加](#コメントの書き方)

6.`npx shiori serve`

- <http://localhost:3000>

7.`shiori/src/Shiori.elm`を編集し外観を変更

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
npx shiori init
npx shiori build
npx shiori serve
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

