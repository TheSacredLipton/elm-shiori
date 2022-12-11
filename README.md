# elm-shiori

カードゲームのUI確認用に作りました。

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
    import Html exposing (Html)
    import Element exposing (Element, layout)


    map : List (Element msg) -> List (Html ())
    map =
        List.map (layout [] >> Html.map (always ()))
    ```
4. `shiori/index.html`を編集し任意のCSSを読み込ませてください

5. `npx shiori serve`で起動
- ブラウザで http://localhost:3000 にアクセス
- 気が向いたらport番号変更できるようにする予定

## コメントの書き方

単体

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

引数有りの場合

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

複数

```elm
{-|

    :: button "World"

    :: button "World2"

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

    :: div [] <| .body <| view { world = "world" }

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

## ライセンス

- MIT license
- [elm-codegen](https://github.com/mdgriffith/elm-codegen)で生成されたコードを一部含みます