## start

```sh
npx elm-codegen run --watch --debug --output="ui-tests/src" --flags-from="elm-stuff/ui-doctest/tmp.json"
```

## install

```sh
npx elm-codegen install
```

## nodemon
```sh
npx nodemon ui-doctest --ignore "ui-tests/**/*" --ignore "elm-stuff/**/*"
```

## reactor

```sh
cd ui-tests
elm reactor
```

## test

```sh
elm-test
chokidar "codegen/**/*.elm" -c "elm-verify-examples && elm-test"
```