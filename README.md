# elm-shiori

カードゲームのUI確認用に作りました

## CLI

```
npx shiori init
npx shiori build
npx shiori serve
```

## 事前準備

- プロジェクトルートで事前に`miyamoen/elm-origami`と`elm/url`をインストールしておいてください

### shiori.json

プロジェクトルートに用意してください

例:

```
{
    "roots": ["examples"],
    "assets": "examples/assets",
    "files": [
        "Shape",
        "Button",
        "Image",
        "Pages.Home_",
        "Pages.Login.Home_"
    ]
}
```