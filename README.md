# elm-shiori

カードゲームを作っていると、あるフェーズのある条件になるまでUIの確認が一切できないという状況が非常に多く面倒だったので作りました。

関数単位でなんかいい感じに使えるビューワーとしてお使いください。

## CLI

```
npx shiori init
npx shiori build
npx shiori serve --port 3000
```

## 事前準備

- プロジェクトルートで事前に`mdgriffith/elm-ui`と`elm/url`をインストールしておいてください
- shiori/src/View.elm, shiori/src/Shiori.elmを編集している場合はelm-uiは必要ないかもしれません

### shiori.json

プロジェクトルートに用意してください

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

### .gitignore

- elm-uiを使っていて特にこだわりがなければshioriディレクトごとgitignoreするといいと思います


## カスタマイズ

```
index.html
Shiori.elm
View.elm
```

編集するとビューワーをカスタマイズしたり、 CSS読み込ませたり、elm-cssとか使ったりできると思います...多分
