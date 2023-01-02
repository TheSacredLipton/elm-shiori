## start

```sh
pnpm nodemon --watch bin -x "node bin/shiori serve"
```

## install

```sh
pnpm elm-codegen install
```

## test

```sh
pnpm elm-test
pnpm chokidar "codegen/**/*.elm" -c "elm-verify-examples && elm-test" &
pnpm chokidar "tests/*.elm" -c "elm-test" &
wait
```

## ci

```sh
pnpm flow check
pnpm elm-verify-examples
pnpm elm-test
```