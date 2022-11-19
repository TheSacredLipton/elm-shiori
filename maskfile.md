## start

```sh
serve -p 8080 &
elm-watch hot &
wait
```

## test

```sh
mask elm-test
chokidar "src/**/*.elm" -c "elm-verify-examples && mask elm-test"
```

## elm-test

```sh
elm-test --fuzz 1
```