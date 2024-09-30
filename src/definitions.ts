export interface BrotherPrintPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
