# elm-shiori

カードゲームのUI確認用に作りました

関数コメントで確認できるビューワーです

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

## CLI

```sh
npx shiori init
npx shiori build
npx shiori serve
```

## ライセンス

- MIT license
- [elm-codegen](https://github.com/mdgriffith/elm-codegen)で生成されたコードを一部含みます