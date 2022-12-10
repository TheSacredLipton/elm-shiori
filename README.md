# elm-shiori

カードゲームのUI確認用に作りました。

関数コメントで確認できるビューワーです。

## インストール

```
npm i elm-shiori
```

## 使い方

1. 準備
- プロジェクトルートで事前に`elm/url`をインストールしておいてください
- `shiori.json`をプロジェクトルートに用意してください

例:

```
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

3. `shiori/Shiori_View.elm`をプロジェクトに合わせて編集してください

4. `npx shiori serve`

## CLI

```
npx shiori init
npx shiori build
npx shiori serve
```

## ライセンス

- MIT license
- [elm-codegen](https://github.com/mdgriffith/elm-codegen)で生成されたコードを一部含みます