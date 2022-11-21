## start

```sh
npx nodemon --watch bin -x "node bin/shiori --watch --serve --dev"
```

## install

```sh
npx elm-codegen install
```

## test

```sh
elm-test
chokidar "codegen/**/*.elm" -c "elm-verify-examples && elm-test"
```