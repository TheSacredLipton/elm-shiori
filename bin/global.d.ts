declare module 'elm-codegen/dist/run' {
  // biome-ignore lint/suspicious/noRedeclare: <explanation>
  // biome-ignore lint/suspicious/noDuplicateParameters: <explanation>
  export function run_generation_from_cli(input: null, { output: string, flags: string }): void;
}

declare module 'node-elm-compiler/dist/index' {
  export function compile(sourceFiles: string[], options: { output: string }): void;
}
