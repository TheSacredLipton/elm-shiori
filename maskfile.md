## start

```sh
npx nodemon --watch bin -x "node bin/shiori serve --dev"
```

## install

```sh
npx flow-typed install
npx elm-codegen install
```

## test

```sh
elm-test
chokidar "codegen/**/*.elm" -c "elm-verify-examples && elm-test"
```

## ci-test

```sh
npx flow check
elm-verify-examples
elm-test
```