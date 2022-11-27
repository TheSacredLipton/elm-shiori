# elm-shiori

カードゲームのUI考えるために作りました。

関数単位でなんかいい感じに使えるビューワーとしてお使いください。

## Cli

```
npx shiori init
npx shiori build
npx shiori serve
```

## 準備

ルートリポジトリ？で事前にインストールしておいてください

ルートにあるelm.jsonをコピーして使っているので動かないです

shiori/src/View.elm, shiori/src/Shiori.elmを編集している場合はelm-uiは必要ないかもしれません

```
elm install mdgriffith/elm-ui
elm install elm/url
```

shiori.jsonをルートリポジトリに用意してください

```
{
    "root": "examples",
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

特にこだわりがなければshioriディレクトごとgitignoreするといいと思います


## カスタマイズ

- index.html
- Shiori.elm
- View.elm

を編集するとビューワーをカスタマイズしたり、 CSS読み込ませたり、elm-cssとか使ったりできると思います...多分
