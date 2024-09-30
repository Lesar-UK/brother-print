import { WebPlugin } from '@capacitor/core';

import type { BrotherPrintPlugin } from './definitions';

export class BrotherPrintWeb extends WebPlugin implements BrotherPrintPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
