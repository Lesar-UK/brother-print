import { WebPlugin } from '@capacitor/core';

import type { BrotherPrintPlugin } from './definitions';

export class BrotherPrintWeb extends WebPlugin implements BrotherPrintPlugin {
  async searchWifiPrinters(): Promise<{ printers: string[] }> {
    console.warn('searchWifiPrinters is not available on the web');
    return { printers: [] }; // Return an empty list for web
  }

  async searchBluetoothPrinters(): Promise<{ printers: string[] }> {
    console.warn('searchBluetoothPrinters is not available on the web');
    return { printers: [] }; // Return an empty list for web
  }

  async printImage(): Promise<{ message: string }> {
    console.warn('base64Print is not available on the web');
    return { message: 'Not available on web' }; // Return an default message
  }

  async printPDF(): Promise<{ message: string }> {
    console.warn('base64Print is not available on the web');
    return { message: 'Not available on web' }; // Return an default message
  }

  async checkPrinterStatus(): Promise<{ status: string[] }> {
    console.warn('checkPrinterStatus is not available on the web');
    return { status: [] }; // Return an empty list
  }
}
