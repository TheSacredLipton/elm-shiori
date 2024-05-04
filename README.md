# elm-shiori

- 自作カードゲームのUI確認モチベで作っています
- storybook + doctest的なツール
- 現状bunの利用必須、クロスコンパイルは気が向いたら

## インストール

```sh
bun add -D elm-shiori
```

## 使い方

1. 準備

- プロジェクトルートで事前に`elm/url`をインストールしておいてください
- `shiori.json`をプロジェクトルートに用意してください

例:

```json
{
    "roots": ["src"],
    "assets": "public",
    "files": [
        "Shape",
        "Button",
        "Image",
        "Pages.Home_",
        "Pages.Login.Home_"
    ]
}
```

2.初回は`bun -b shiori init`を実行

3.プロジェクトに合わせて`shiori/Shiori_View.elm`を編集してください

例: elm-ui

```elm
import Html exposing (Html)
import Element exposing (Element, layout)


map : List (Element msg) -> List (Html ())
map =
    List.map (layout [] >> Html.map (always ()))
```

4.`shiori/index.html`を編集し任意のCSSやjs等読み込ませてください

5.`bun -b shiori serve`で起動

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

global install必要

- bun
- elm

### 検証

```sh
bun add -D https://github.com/TheSacredLipton/elm-shiori.git#branch-name
```

### publish

```sh
bun npm-publish
```

## ライセンス

- MIT license
- 一部[elm-codegen](https://github.com/mdgriffith/elm-codegen)で生成されたコードを含みます
