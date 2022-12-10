## start

```sh
npx nodemon --watch bin -x "node bin/shiori serve"
```

## install

```sh
npx elm-codegen install
```

## test

```sh
elm-test
chokidar "codegen/**/*.elm" -c "elm-verify-examples && elm-test" &
chokidar "tests/*.elm" -c "elm-test" &
wait
```

## ci-test

```sh
npx flow check
elm-verify-examples
elm-test
```