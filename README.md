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

- プロジェクトルートで事前に`miyamoen/elm-origami`と`elm/url`をインストールしておいてください

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

- 特にこだわりがなければshioriディレクトごとgitignoreするといいと思います