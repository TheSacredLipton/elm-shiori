declare module 'elm-codegen/dist/run' {
  // biome-ignore lint/suspicious/noRedeclare: <explanation>
  // biome-ignore lint/suspicious/noDuplicateParameters: <explanation>
  export function run_generation_from_cli(input: null, { output: string, flags: string }): void;
}

declare module 'node-elm-compiler' {
  export function compile(sourceFiles: string[], options: { output: string }): void;
  const compiler: {
    compile: typeof compile;
  };
  export default compiler;
}
