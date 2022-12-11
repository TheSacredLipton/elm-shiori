# elm-shiori

カードゲームのUI確認用に作りました

## インストール

```sh
npm i -D elm-shiori
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

2. 初回は`npx shiori init`を実行

3. プロジェクトに合わせて`shiori/Shiori_View.elm`を編集してください

例: elm-ui

```elm
import Html
import Element exposing (Element, map, layout)


map : List (Element msg) -> List (Html.Html ())
map =
    List.map (layout [] >> Html.map (always ()))
```

4. `npx shiori serve`

## コメントの書き方

- 単体

```elm
{-|

    :: button

-}
button : Html Msg
button =
    div []
        [ Html.button [ onClick Sample ] [ text "button" ]
        ]
```

- 引数有りの場合

```elm
{-|

    :: button "World"

-}
button : String -> Html Msg
button str =
    div []
        [ Html.button [ onClick Sample ] [ text <| "Hello " ++ str ]
        ]
```

- import

```elm
{-|

    import Html exposing (div)

    :: div [] <| .body <| view { world = "world" }

-}
view : Model -> { title : String, body : List (Html Msg) }
view model =
    { title = "home"
    , body = [ text <| "hello " ++ model.world ]
    }

```

## CLI

```sh
npx shiori init
npx shiori build
npx shiori serve
```

## ライセンス

- MIT license
- [elm-codegen](https://github.com/mdgriffith/elm-codegen)で生成されたコードを一部含みます